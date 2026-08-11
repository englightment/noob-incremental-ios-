import Foundation
import UIKit
import Combine

/// Cost/affordability is precomputed for every bulk-buy tier since the ViewModel has no
/// visibility into which x1/x10/x100/Max option is currently selected in the UI.
struct GeneratorRowViewData: Identifiable {
    let id: String
    let name: String
    let zoneID: String
    let level: Int
    let isLocked: Bool
    let unlockText: String
    let outputPerLevelText: String
    let costX1: String
    let canAffordX1: Bool
    let costX10: String
    let canAffordX10: Bool
    let costX100: String
    let canAffordX100: Bool
    let maxAffordableCount: Int
    let milestoneBonusText: String?
    let nextMilestoneText: String?
}

struct WorldRowViewData: Identifiable {
    let id: String
    let name: String
    let icon: String
    let isUnlocked: Bool
    let lockedDescription: String
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

struct AchievementRowViewData: Identifiable {
    let id: String
    let name: String
    let description: String
    let isUnlocked: Bool
    let progressText: String?
}

struct MinionRowViewData: Identifiable {
    let id: String
    let name: String
    let icon: String
    let isOwned: Bool
    let isEquipped: Bool
    let unlockHint: String
    let bonusText: String
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
    @Published private(set) var achievementToast: AchievementDefinition?
    @Published private(set) var showMilestoneCelebration = false
    @Published private(set) var redeemMessage: String?

    private let saveManager: SaveManager
    private var refreshTimer: Timer?
    private var autosaveTimer: Timer?
    private var lastTickDate = Date()
    private var pendingFloatingIncome: Decimal = 0
    private var lastFloatingTextSpawn = Date.distantPast
    private var lastBoostRoll = Date.distantPast
    private var achievementToastQueue: [AchievementDefinition] = []

    private let buyHaptic = UIImpactFeedbackGenerator(style: .light)
    private let successHaptic = UINotificationFeedbackGenerator()

    private let boostRollInterval: TimeInterval = 15
    private let boostChance: Double = 0.12
    private let boostDuration: TimeInterval = 20
    private let boostMultiplier: Decimal = 5

    // MARK: - Currency / income

    var formattedCurrency: String { NumberFormatting.format(state.currency) }

    var formattedIncomePerSecond: String {
        let perSecond = GameLoop.passiveIncomePerSecond(state)
        guard perSecond > 0 else { return "" }
        return "+\(NumberFormatting.format(perSecond))/sec"
    }

    // MARK: - Lucky Surge boost

    var isBoostActive: Bool { BoostSystem.isActive(state: state) }
    var boostMultiplierText: String { "x\(NumberFormatting.format(state.activeBoostMultiplier, fractionDigits: 0))" }
    var boostRemainingSecondsText: String {
        String(format: "%.0fs", BoostSystem.remainingSeconds(state: state))
    }

    // MARK: - Rewarded-ad boosts

    func isAdBoostActive(_ tier: AdBoostTier) -> Bool {
        AdBoostSystem.isActive(tier, state: state)
    }

    func adBoostRemainingText(_ tier: AdBoostTier) -> String {
        formatHoursMinutes(AdBoostSystem.remainingSeconds(tier, state: state))
    }

    /// Pure state update — the View owns the actual ad loading/presentation and calls this
    /// once the SDK confirms the reward was earned.
    func grantAdBoost(_ tier: AdBoostTier) {
        state = AdBoostSystem.activate(tier, state: state, duration: GameBalance.adBoostDuration)
        fireHapticNotification(.success)
        SoundManager.play(.milestone, enabled: state.soundEnabled)
        checkForAchievements()
    }

    private func formatHoursMinutes(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "" }
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    // MARK: - Daily streak

    var currentStreak: Int { state.currentStreak }
    var canClaimDailyReward: Bool { DailyStreakSystem.canClaim(state: state) }

    var pendingStreakDay: Int { DailyStreakSystem.pendingStreakValue(state: state) }

    var pendingDailyRewardText: String {
        let reward = DailyRewardCatalog.reward(forStreak: pendingStreakDay)
        var parts: [String] = []
        if reward.oof > 0 { parts.append("+\(NumberFormatting.format(reward.oof)) Oof") }
        if reward.rebirthCurrency > 0 { parts.append("+\(NumberFormatting.format(reward.rebirthCurrency)) Rebirth") }
        if reward.runeShards > 0 { parts.append("+\(NumberFormatting.format(reward.runeShards)) Rune Shards") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Rebirth

    var rebirthCount: Int { state.rebirthCount }
    var formattedRebirthCurrency: String { NumberFormatting.format(state.rebirthCurrency) }
    var canRebirth: Bool { RebirthSystem.canRebirth(state: state) }

    var rebirthGainPreviewText: String {
        "+\(NumberFormatting.format(RebirthSystem.availableGain(state: state)))"
    }

    var rebirthRequirementText: String {
        "Requirement: \(NumberFormatting.format(RebirthSystem.requirement(rebirthCount: state.rebirthCount))) Oof"
    }

    var rebirthProgressFraction: Double {
        let requirement = RebirthSystem.requirement(rebirthCount: state.rebirthCount)
        guard requirement > 0 else { return 0 }
        let capped = min(state.currency / requirement, 1)
        return NSDecimalNumber(decimal: capped).doubleValue
    }

    // MARK: - Runes

    var formattedRuneShards: String { NumberFormatting.format(state.runeShards) }

    var runeRows: [UpgradeRowViewData] {
        rowData(for: RuneCatalog.all, level: { RuneStore.level($0, state: self.state) }, isMaxed: { RuneStore.isMaxed($0, state: self.state) }, cost: { RuneStore.cost(for: $0, state: self.state) }, canAfford: { RuneStore.canAfford($0, state: self.state) })
    }

    // MARK: - Settings

    var soundEnabled: Bool { state.soundEnabled }
    var hapticsEnabled: Bool { state.hapticsEnabled }
    var offlineReminderEnabled: Bool { state.offlineReminderEnabled }

    // MARK: - Stats

    var totalNoobLevels: Int {
        GeneratorCatalog.all.reduce(0) { $0 + GeneratorStore.level($1, state: state) }
    }
    var lifetimeEarnedText: String { NumberFormatting.format(state.lifetimeEarned) }
    var lifetimeEarned: Decimal { state.lifetimeEarned }
    var totalPlayTimeText: String {
        let total = Int(state.totalPlayTime)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    var unlockedAchievementCount: Int { state.unlockedAchievements.count }
    var totalAchievementCount: Int { AchievementCatalog.all.count }
    var unlockedAchievementIDs: [String] { Array(state.unlockedAchievements) }

    var achievementRows: [AchievementRowViewData] {
        AchievementStore.sortedForDisplay(state: state).map { definition in
            let isUnlocked = AchievementStore.isUnlocked(definition, state: state)
            return AchievementRowViewData(
                id: definition.id,
                name: definition.name,
                description: definition.description,
                isUnlocked: isUnlocked,
                progressText: isUnlocked ? nil : achievementProgressText(definition)
            )
        }
    }

    private func achievementProgressText(_ definition: AchievementDefinition) -> String? {
        guard let (current, target) = AchievementStore.progress(definition, state: state) else { return nil }
        let clampedCurrent = min(current, target)
        if case .lifetimeEarned = definition.condition {
            return "\(NumberFormatting.format(clampedCurrent)) / \(NumberFormatting.format(target))"
        }
        return "\(NumberFormatting.format(clampedCurrent, fractionDigits: 0)) / \(NumberFormatting.format(target, fractionDigits: 0))"
    }

    // MARK: - Minions

    var equippedMinionCount: Int { MinionSystem.equippedCount(state: state) }
    var maxEquippedMinions: Int { MinionSystem.maxEquipped(state: state) }

    var minionRows: [MinionRowViewData] {
        MinionCatalog.all.map { definition in
            MinionRowViewData(
                id: definition.id,
                name: definition.name,
                icon: definition.icon,
                isOwned: MinionSystem.isOwned(definition, state: state),
                isEquipped: MinionSystem.isEquipped(definition, state: state),
                unlockHint: definition.unlockHint,
                bonusText: "+\(NumberFormatting.format(definition.outputBonus * 100, fractionDigits: 0))% Oof"
            )
        }
    }

    func toggleMinionEquip(id: String) {
        guard let definition = MinionCatalog.definition(for: id) else { return }
        state = MinionSystem.toggleEquip(definition, state: state)
        fireHapticNotification(.success)
    }

    // MARK: - Worlds

    var worldRows: [WorldRowViewData] {
        WorldCatalog.all.map { world in
            WorldRowViewData(
                id: world.id,
                name: world.name,
                icon: world.icon,
                isUnlocked: WorldSystem.isUnlocked(world, state: state),
                lockedDescription: world.lockedDescription
            )
        }
    }

    // MARK: - Shop rows

    var generatorRows: [GeneratorRowViewData] {
        GeneratorCatalog.all.map { definition in
            let level = GeneratorStore.level(definition, state: state)
            let milestoneMultiplier = GeneratorMilestoneSystem.multiplier(level: level)
            let nextThreshold = GeneratorMilestoneSystem.nextThreshold(level: level)

            return GeneratorRowViewData(
                id: definition.id,
                name: definition.name,
                zoneID: definition.zoneID,
                level: level,
                isLocked: !definition.isVisible(for: state),
                unlockText: "Unlocks at \(NumberFormatting.format(definition.unlockThreshold)) Oof",
                outputPerLevelText: "\(NumberFormatting.format(definition.baseOutput))/sec per level",
                costX1: NumberFormatting.format(GeneratorStore.costForQuantity(definition, quantity: 1, state: state)),
                canAffordX1: GeneratorStore.canAffordQuantity(definition, quantity: 1, state: state),
                costX10: NumberFormatting.format(GeneratorStore.costForQuantity(definition, quantity: 10, state: state)),
                canAffordX10: GeneratorStore.canAffordQuantity(definition, quantity: 10, state: state),
                costX100: NumberFormatting.format(GeneratorStore.costForQuantity(definition, quantity: 100, state: state)),
                canAffordX100: GeneratorStore.canAffordQuantity(definition, quantity: 100, state: state),
                maxAffordableCount: GeneratorStore.maxAffordableCount(definition, state: state),
                milestoneBonusText: milestoneMultiplier > 1 ? "x\(NumberFormatting.format(milestoneMultiplier, fractionDigits: 0)) milestone bonus" : nil,
                nextMilestoneText: nextThreshold.map { threshold in
                    "Lv \(threshold) \u{2192} x\(NumberFormatting.format(GeneratorMilestoneSystem.multiplier(level: threshold), fractionDigits: 0))"
                }
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
        let synced = MinionSystem.syncOwnership(state: offline.state)
        self.state = OnboardingSystem.backfillIfNeeded(synced)
        self.lastOfflineEarnings = offline.currencyEarned > 0 ? offline.currencyEarned : nil
    }

    func start() {
        OfflineReminderManager.cancelReminder()
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
        guard state.offlineReminderEnabled else { return }
        let offlineCap = GameBalance.maxOfflineProgressDuration + RebirthUpgradeStore.offlineCapBonus(state: state)
        OfflineReminderManager.scheduleReminder(after: offlineCap)
    }

    func dismissOfflineEarningsBanner() {
        lastOfflineEarnings = nil
    }

    // MARK: - First-launch onboarding

    var showOnboarding: Bool { OnboardingSystem.shouldShowOnboarding(state) }

    func dismissOnboarding() {
        state = OnboardingSystem.dismiss(state)
    }

    // MARK: - Purchases

    func buyGenerator(id: String, quantity: Int = 1) {
        guard let definition = GeneratorCatalog.definition(for: id) else { return }
        let before = GeneratorStore.level(definition, state: state)
        state = GeneratorStore.buyQuantity(definition, quantity: quantity, state: state)
        let after = GeneratorStore.level(definition, state: state)
        if after > before {
            fireBuyFeedback()
            fireGeneratorMilestoneFeedbackIfCrossed(from: before, to: after)
        }
        checkForAchievements()
    }

    func buyGeneratorMax(id: String) {
        guard let definition = GeneratorCatalog.definition(for: id) else { return }
        let before = GeneratorStore.level(definition, state: state)
        state = GeneratorStore.buyMax(definition, state: state)
        let after = GeneratorStore.level(definition, state: state)
        if after > before {
            fireBuyFeedback()
            fireGeneratorMilestoneFeedbackIfCrossed(from: before, to: after)
        }
        checkForAchievements()
    }

    private func fireGeneratorMilestoneFeedbackIfCrossed(from before: Int, to after: Int) {
        guard GeneratorMilestoneSystem.crossedCount(from: before, to: after) > 0 else { return }
        fireHapticNotification(.success)
        SoundManager.play(.milestone, enabled: state.soundEnabled)
    }

    func buyUpgrade(id: String) {
        guard let definition = UpgradeCatalog.definition(for: id),
              UpgradeStore.canAfford(definition, state: state) else { return }
        state = UpgradeStore.buyOne(definition, state: state)
        fireBuyFeedback()
        checkForAchievements()
    }

    func buyUpgradeMax(id: String) {
        guard let definition = UpgradeCatalog.definition(for: id) else { return }
        let before = UpgradeStore.level(definition, state: state)
        state = UpgradeStore.buyMax(definition, state: state)
        if UpgradeStore.level(definition, state: state) > before {
            fireBuyFeedback()
        }
        checkForAchievements()
    }

    func buyRebirthUpgrade(id: String) {
        guard let definition = RebirthUpgradeCatalog.definition(for: id),
              RebirthUpgradeStore.canAfford(definition, state: state) else { return }
        state = RebirthUpgradeStore.buyOne(definition, state: state)
        fireBuyFeedback()
        checkForAchievements()
    }

    func buyRebirthUpgradeMax(id: String) {
        guard let definition = RebirthUpgradeCatalog.definition(for: id) else { return }
        let before = RebirthUpgradeStore.level(definition, state: state)
        state = RebirthUpgradeStore.buyMax(definition, state: state)
        if RebirthUpgradeStore.level(definition, state: state) > before {
            fireBuyFeedback()
        }
        checkForAchievements()
    }

    func buyRune(id: String) {
        guard let definition = RuneCatalog.definition(for: id),
              RuneStore.canAfford(definition, state: state) else { return }
        state = RuneStore.buyOne(definition, state: state)
        fireBuyFeedback()
        checkForAchievements()
    }

    func buyRuneMax(id: String) {
        guard let definition = RuneCatalog.definition(for: id) else { return }
        let before = RuneStore.level(definition, state: state)
        state = RuneStore.buyMax(definition, state: state)
        if RuneStore.level(definition, state: state) > before {
            fireBuyFeedback()
        }
        checkForAchievements()
    }

    func claimDailyReward() {
        guard let (newState, _) = DailyStreakSystem.claim(state: state) else { return }
        state = newState
        fireHapticNotification(.success)
        SoundManager.play(.milestone, enabled: state.soundEnabled)
        checkForAchievements()
    }

    func performRebirth() {
        guard RebirthSystem.canRebirth(state: state) else { return }
        state = RebirthSystem.performRebirth(state: state)
        fireHapticNotification(.success)
        SoundManager.play(.rebirth, enabled: state.soundEnabled)
        checkForAchievements()
    }

    func redeemCode(_ code: String) {
        let (newState, result) = RedeemCodeStore.redeem(code, state: state)
        state = newState
        switch result {
        case .success(let definition):
            redeemMessage = "Redeemed \(definition.code)!"
            fireBuyFeedback()
        case .alreadyRedeemed:
            redeemMessage = "Already redeemed."
        case .invalid:
            redeemMessage = "Invalid code."
        }
        checkForAchievements()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self?.redeemMessage = nil
        }
    }

    // MARK: - Share progress

    var shareSummaryText: String {
        ShareSummary.text(state: state)
    }

    // MARK: - App Store review prompt

    var shouldRequestReview: Bool {
        ReviewPromptSystem.shouldRequest(state: state)
    }

    /// Flips the one-shot guard. Called as soon as the caller decides to ask, independent of
    /// whether StoreKit actually shows the system prompt (it rate-limits itself) — this guard
    /// exists so the app itself never asks more than once, not to track whether it was shown.
    func markReviewRequested() {
        state.hasRequestedReview = true
    }

    // MARK: - In-app purchases

    func isProductOwned(_ product: IAPProduct) -> Bool {
        IAPSystem.isOwned(product, state: state)
    }

    /// Applies a StoreKit transaction already verified by IAPManager. Safe to call more than
    /// once for the same non-consumable (IAPSystem.applyPurchase is idempotent for those).
    func completePurchase(_ product: IAPProduct) {
        state = IAPSystem.applyPurchase(product, to: state)
        fireBuyFeedback()
        checkForAchievements()
    }

    // MARK: - Settings

    func toggleSound() { state.soundEnabled.toggle() }
    func toggleHaptics() { state.hapticsEnabled.toggle() }
    func toggleOfflineReminder() { state.offlineReminderEnabled.toggle() }

    func resetSave() {
        stop()
        state = .newGame
        saveManager.save(state)
        start()
    }

    // MARK: - Save backup/restore

    enum ImportSaveResult {
        case success
        case invalidCode
    }

    func exportSaveCode() -> String? {
        saveManager.exportCode(state)
    }

    /// Replaces the current save with the one encoded in `code`. Runs the same
    /// ownership-sync/onboarding-backfill pass as a fresh load so an imported save (which
    /// might be older, or from a different point in this session) ends up just as consistent
    /// as one loaded at launch.
    func importSaveCode(_ code: String) -> ImportSaveResult {
        guard let imported = saveManager.decodeImportCode(code) else { return .invalidCode }
        let synced = MinionSystem.syncOwnership(state: imported)
        state = OnboardingSystem.backfillIfNeeded(synced)
        saveManager.save(state)
        return .success
    }

    // MARK: - Tick

    private func tick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickDate)
        lastTickDate = now

        let before = state.currency
        state = GameLoop.tick(state, elapsed: elapsed, now: now)
        pendingFloatingIncome += state.currency - before

        if pendingFloatingIncome > 0, now.timeIntervalSince(lastFloatingTextSpawn) >= 1.0 {
            spawnFloatingText(pendingFloatingIncome)
            pendingFloatingIncome = 0
            lastFloatingTextSpawn = now
        }

        rollLuckySurge(now: now)
        checkForMilestone()
        checkForAchievements()
    }

    private func rollLuckySurge(now: Date) {
        guard !BoostSystem.isActive(state: state, now: now) else { return }
        guard now.timeIntervalSince(lastBoostRoll) >= boostRollInterval else { return }
        lastBoostRoll = now
        guard Double.random(in: 0..<1) < boostChance else { return }
        state = BoostSystem.start(state: state, multiplier: boostMultiplier, duration: boostDuration, now: now)
        state.runeShards += Decimal(Int.random(in: GameBalance.runeShardsPerLuckySurge))
        fireHapticNotification(.success)
        SoundManager.play(.luckySurge, enabled: state.soundEnabled)
    }

    private func checkForMilestone() {
        guard MilestoneSystem.hasNewMilestone(state: state) else { return }
        state = MilestoneSystem.celebrate(state: state)
        state.runeShards += GameBalance.runeShardsPerMilestone
        showMilestoneCelebration = true
        SoundManager.play(.milestone, enabled: state.soundEnabled)
        fireHapticNotification(.success)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            self?.showMilestoneCelebration = false
        }
    }

    private func checkForAchievements() {
        let (newState, unlocked) = AchievementStore.unlockNewlyMet(state: state)
        guard !unlocked.isEmpty else { return }
        state = MinionSystem.syncOwnership(state: newState)
        achievementToastQueue.append(contentsOf: unlocked)
        SoundManager.play(.achievement, enabled: state.soundEnabled)
        advanceAchievementToastIfNeeded()
    }

    private func advanceAchievementToastIfNeeded() {
        guard achievementToast == nil, !achievementToastQueue.isEmpty else { return }
        let next = achievementToastQueue.removeFirst()
        achievementToast = next
        fireHapticNotification(.success)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self?.achievementToast = nil
            self?.advanceAchievementToastIfNeeded()
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

    private func fireBuyFeedback() {
        if state.hapticsEnabled {
            buyHaptic.impactOccurred()
        }
        SoundManager.play(.buy, enabled: state.soundEnabled)
    }

    private func fireHapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard state.hapticsEnabled else { return }
        successHaptic.notificationOccurred(type)
    }

    private func save() {
        var toSave = state
        toSave.lastSaveTimestamp = Date()
        state = toSave
        saveManager.save(toSave)
    }
}
