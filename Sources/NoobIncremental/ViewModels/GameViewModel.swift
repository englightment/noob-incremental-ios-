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

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var lastOfflineEarnings: Decimal?

    private let saveManager: SaveManager
    private var refreshTimer: Timer?
    private var autosaveTimer: Timer?
    private var lastTickDate = Date()
    private let buyHaptic = UIImpactFeedbackGenerator(style: .light)

    var formattedCurrency: String { NumberFormatting.format(state.currency) }

    var formattedIncomePerSecond: String {
        let perSecond = GameLoop.passiveIncomePerSecond(state)
        guard perSecond > 0 else { return "" }
        return "+\(NumberFormatting.format(perSecond))/sec"
    }

    var prestigeCount: Int { state.prestigeCount }

    var prestigeProgressText: String {
        "\(NumberFormatting.format(state.lifetimeEarned))/\(NumberFormatting.format(GameBalance.prestigeThreshold)) Oofs"
    }

    var prestigeProgressFraction: Double {
        guard GameBalance.prestigeThreshold > 0 else { return 0 }
        let capped = min(state.lifetimeEarned / GameBalance.prestigeThreshold, 1)
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
        UpgradeCatalog.all.map { definition in
            let level = UpgradeStore.level(definition, state: state)
            let maxed = UpgradeStore.isMaxed(definition, state: state)
            return UpgradeRowViewData(
                id: definition.id,
                name: definition.name,
                level: level,
                maxLevel: definition.maxLevel,
                effectText: definition.effect.description(atLevel: level),
                costText: maxed ? "MAX" : NumberFormatting.format(UpgradeStore.cost(for: definition, state: state)),
                isMaxed: maxed,
                canAfford: UpgradeStore.canAfford(definition, state: state)
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

    private func tick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickDate)
        lastTickDate = now
        state = GameLoop.tick(state, elapsed: elapsed)
    }

    private func save() {
        var toSave = state
        toSave.lastSaveTimestamp = Date()
        state = toSave
        saveManager.save(toSave)
    }
}
