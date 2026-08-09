import Foundation
import UIKit
import Combine

struct GeneratorRowViewData: Identifiable {
    let id: String
    let name: String
    let level: Int
    let costText: String
    let outputPerLevelText: String
    let canAfford: Bool
}

struct UpgradeRowViewData: Identifiable {
    let id: String
    let name: String
    let level: Int
    let maxLevel: Int
    let effectText: String
    let costText: String
    let isMaxed: Bool
    let canAfford: Bool
}

struct FloatingText: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let xOffset: Double
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var lastOfflineEarnings: Decimal?
    @Published private(set) var floatingTexts: [FloatingText] = []

    private let saveManager: SaveManager
    private var refreshTimer: Timer?
    private var autosaveTimer: Timer?
    private var lastTickDate = Date()
    private var pendingFloatingIncome: Decimal = 0
    private var lastFloatingTextSpawn = Date.distantPast
    private let buyHaptic = UIImpactFeedbackGenerator(style: .light)
    private let rebirthHaptic = UINotificationFeedbackGenerator()

    var formattedCurrency: String { NumberFormatting.format(state.currency) }

    var formattedIncomePerSecond: String {
        let perSecond = GameLoop.passiveIncomePerSecond(state)
        guard perSecond > 0 else { return "" }
        return "+\(NumberFormatting.format(perSecond))/sec"
    }

    // MARK: - Rebirth

    var rebirthCount: Int { state.rebirthCount }
    var formattedRebirthCurrency: String { NumberFormatting.format(state.rebirthCurrency) }
    var canRebirth: Bool { RebirthSystem.canRebirth(state: state) }

    var rebirthGainPreviewText: String {
        "+\(NumberFormatting.format(RebirthSystem.availableGain(state: state)))"
    }

    var rebirthRequirementText: String {
        "Requirement: \(NumberFormatting.format(GameBalance.rebirthRequirement)) Oof"
    }

    var rebirthProgressFraction: Double {
        guard GameBalance.rebirthRequirement > 0 else { return 0 }
        let capped = min(state.currency / GameBalance.rebirthRequirement, 1)
        return NSDecimalNumber(decimal: capped).doubleValue
    }

    var visibleGenerators: [GeneratorRowViewData] {
        GeneratorCatalog.all
            .filter { $0.isVisible(for: state) }
            .map { definition in
                GeneratorRowViewData(
                    id: definition.id,
                    name: definition.name,
                    level: GeneratorStore.level(definition, state: state),
                    costText: NumberFormatting.format(GeneratorStore.cost(for: definition, state: state)),
                    outputPerLevelText: "\(NumberFormatting.format(definition.baseOutput))/sec per level",
                    canAfford: GeneratorStore.canAfford(definition, state: state)
                )
            }
    }

    var visibleUpgrades: [UpgradeRowViewData] {
        rowData(for: UpgradeCatalog.all, level: { UpgradeStore.level($0, state: self.state) }, isMaxed: { UpgradeStore.isMaxed($0, state: self.state) }, cost: { UpgradeStore.cost(for: $0, state: self.state) }, canAfford: { UpgradeStore.canAfford($0, state: self.state) })
    }

    var visibleRebirthUpgrades: [UpgradeRowViewData] {
        rowData(for: RebirthUpgradeCatalog.all, level: { RebirthUpgradeStore.level($0, state: self.state) }, isMaxed: { RebirthUpgradeStore.isMaxed($0, state: self.state) }, cost: { RebirthUpgradeStore.cost(for: $0, state: self.state) }, canAfford: { RebirthUpgradeStore.canAfford($0, state: self.state) })
    }

    private func rowData(
        for definitions: [UpgradeDefinition],
        level: (UpgradeDefinition) -> Int,
        isMaxed: (UpgradeDefinition) -> Bool,
        cost: (UpgradeDefinition) -> Decimal,
        canAfford: (UpgradeDefinition) -> Bool
    ) -> [UpgradeRowViewData] {
        definitions.map { definition in
            let lvl = level(definition)
            let maxed = isMaxed(definition)
            return UpgradeRowViewData(
                id: definition.id,
                name: definition.name,
                level: lvl,
                maxLevel: definition.maxLevel,
                effectText: definition.effect.description(atLevel: lvl),
                costText: maxed ? "MAX" : NumberFormatting.format(cost(definition)),
                isMaxed: maxed,
                canAfford: canAfford(definition)
            )
        }
    }

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let loaded = saveManager.load()
        let offline = OfflineProgress.apply(to: loaded)
        self.state = offline.state
        self.lastOfflineEarnings = offline.currencyEarned > 0 ? offline.currencyEarned : nil
    }

    func start() {
        lastTickDate = Date()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: GameBalance.uiRefreshInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: GameBalance.autosaveInterval, repeats: true) { [weak self] _ in
            self?.save()
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        autosaveTimer?.invalidate()
        autosaveTimer = nil
        save()
    }

    func dismissOfflineEarningsBanner() {
        lastOfflineEarnings = nil
    }

    func buyGenerator(id: String) {
        guard let definition = GeneratorCatalog.definition(for: id),
              GeneratorStore.canAfford(definition, state: state) else { return }
        state = GeneratorStore.buy(definition, state: state)
        buyHaptic.impactOccurred()
    }

    func buyUpgrade(id: String) {
        guard let definition = UpgradeCatalog.definition(for: id),
              UpgradeStore.canAfford(definition, state: state) else { return }
        state = UpgradeStore.buyOne(definition, state: state)
        buyHaptic.impactOccurred()
    }

    func buyUpgradeMax(id: String) {
        guard let definition = UpgradeCatalog.definition(for: id) else { return }
        let before = UpgradeStore.level(definition, state: state)
        state = UpgradeStore.buyMax(definition, state: state)
        if UpgradeStore.level(definition, state: state) > before {
            buyHaptic.impactOccurred()
        }
    }

    func buyRebirthUpgrade(id: String) {
        guard let definition = RebirthUpgradeCatalog.definition(for: id),
              RebirthUpgradeStore.canAfford(definition, state: state) else { return }
        state = RebirthUpgradeStore.buyOne(definition, state: state)
        buyHaptic.impactOccurred()
    }

    func buyRebirthUpgradeMax(id: String) {
        guard let definition = RebirthUpgradeCatalog.definition(for: id) else { return }
        let before = RebirthUpgradeStore.level(definition, state: state)
        state = RebirthUpgradeStore.buyMax(definition, state: state)
        if RebirthUpgradeStore.level(definition, state: state) > before {
            buyHaptic.impactOccurred()
        }
    }

    func performRebirth() {
        guard RebirthSystem.canRebirth(state: state) else { return }
        state = RebirthSystem.performRebirth(state: state)
        rebirthHaptic.notificationOccurred(.success)
    }

    private func tick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickDate)
        lastTickDate = now

        let before = state.currency
        state = GameLoop.tick(state, elapsed: elapsed)
        pendingFloatingIncome += state.currency - before

        if pendingFloatingIncome > 0, now.timeIntervalSince(lastFloatingTextSpawn) >= 1.0 {
            spawnFloatingText(pendingFloatingIncome)
            pendingFloatingIncome = 0
            lastFloatingTextSpawn = now
        }
    }

    private func spawnFloatingText(_ amount: Decimal) {
        let item = FloatingText(text: "+\(NumberFormatting.format(amount))", xOffset: Double.random(in: -50...50))
        floatingTexts.append(item)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            self?.floatingTexts.removeAll { $0.id == item.id }
        }
    }

    private func save() {
        var toSave = state
        toSave.lastSaveTimestamp = Date()
        state = toSave
        saveManager.save(toSave)
    }
}
