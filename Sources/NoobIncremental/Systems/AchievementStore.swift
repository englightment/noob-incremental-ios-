import Foundation

/// Achievement unlock detection, application, and their permanent (small, stacking)
/// production bonus. Placeholder +2%-per-achievement reward — tune once real numbers exist.
enum AchievementStore {

    static let outputMultiplierPerAchievement: Decimal = 0.02

    static func isUnlocked(_ definition: AchievementDefinition, state: GameState) -> Bool {
        state.unlockedAchievements.contains(definition.id)
    }

    static func conditionMet(_ definition: AchievementDefinition, state: GameState) -> Bool {
        switch definition.condition {
        case .lifetimeEarned(let amount):
            return state.lifetimeEarned >= amount
        case .rebirths(let count):
            return state.rebirthCount >= count
        case .totalNoobLevels(let total):
            return totalNoobLevels(state: state) >= total
        case .allNoobsOwned:
            return GeneratorCatalog.all.allSatisfy { GeneratorStore.level($0, state: state) > 0 }
        case .upgradeMaxed(let id):
            if let def = UpgradeCatalog.definition(for: id) { return UpgradeStore.isMaxed(def, state: state) }
            if let def = RebirthUpgradeCatalog.definition(for: id) { return RebirthUpgradeStore.isMaxed(def, state: state) }
            if let def = RuneCatalog.definition(for: id) { return RuneStore.isMaxed(def, state: state) }
            return false
        case .codeRedeemed:
            return !state.redeemedCodes.isEmpty
        case .streakDays(let days):
            return state.longestStreak >= days
        case .zoneNoobLevels(let zoneID, let total):
            return totalNoobLevels(state: state, zoneID: zoneID) >= total
        case .allRunesOwned:
            return RuneCatalog.all.allSatisfy { RuneStore.level($0, state: state) > 0 }
        case .allMinionsOwned:
            return MinionCatalog.all.allSatisfy { MinionSystem.isOwned($0, state: state) }
        case .allZoneNoobsOwned(let zoneID):
            return GeneratorCatalog.all(inZone: zoneID).allSatisfy { GeneratorStore.level($0, state: state) > 0 }
        case .productOwned(let productID):
            return state.purchasedProductIDs.contains(productID)
        }
    }

    /// (current, target) toward a condition, for showing "how close am I" on locked
    /// achievements — nil for conditions with no meaningful fractional reading (codeRedeemed
    /// is binary: either a code has been redeemed or it hasn't).
    static func progress(_ definition: AchievementDefinition, state: GameState) -> (current: Decimal, target: Decimal)? {
        switch definition.condition {
        case .lifetimeEarned(let amount):
            return (state.lifetimeEarned, amount)
        case .rebirths(let count):
            return (Decimal(state.rebirthCount), Decimal(count))
        case .totalNoobLevels(let total):
            return (Decimal(totalNoobLevels(state: state)), Decimal(total))
        case .streakDays(let days):
            return (Decimal(state.longestStreak), Decimal(days))
        case .zoneNoobLevels(let zoneID, let total):
            return (Decimal(totalNoobLevels(state: state, zoneID: zoneID)), Decimal(total))
        case .allNoobsOwned:
            return (Decimal(ownedCount(GeneratorCatalog.all, isOwned: { GeneratorStore.level($0, state: state) > 0 })), Decimal(GeneratorCatalog.all.count))
        case .allZoneNoobsOwned(let zoneID):
            let zoneGenerators = GeneratorCatalog.all(inZone: zoneID)
            return (Decimal(ownedCount(zoneGenerators, isOwned: { GeneratorStore.level($0, state: state) > 0 })), Decimal(zoneGenerators.count))
        case .allRunesOwned:
            return (Decimal(ownedCount(RuneCatalog.all, isOwned: { RuneStore.level($0, state: state) > 0 })), Decimal(RuneCatalog.all.count))
        case .allMinionsOwned:
            return (Decimal(ownedCount(MinionCatalog.all, isOwned: { MinionSystem.isOwned($0, state: state) })), Decimal(MinionCatalog.all.count))
        case .upgradeMaxed(let id):
            if let def = UpgradeCatalog.definition(for: id) { return (Decimal(UpgradeStore.level(def, state: state)), Decimal(def.maxLevel)) }
            if let def = RebirthUpgradeCatalog.definition(for: id) { return (Decimal(RebirthUpgradeStore.level(def, state: state)), Decimal(def.maxLevel)) }
            if let def = RuneCatalog.definition(for: id) { return (Decimal(RuneStore.level(def, state: state)), Decimal(def.maxLevel)) }
            return nil
        case .codeRedeemed:
            return nil
        case .productOwned:
            return nil
        }
    }

    /// 0...1 reading of how close a condition is to being met — 0 for conditions with no
    /// fractional progress (see `progress(_:state:)`).
    static func progressFraction(_ definition: AchievementDefinition, state: GameState) -> Double {
        guard let (current, target) = progress(definition, state: state), target > 0 else { return 0 }
        return NSDecimalNumber(decimal: min(current, target) / target).doubleValue
    }

    /// Display order: unlocked achievements first (a stable "trophy wall" — their relative
    /// order never changes once earned), then locked ones sorted closest-to-completion first,
    /// so the list reads as "here's what to chase next" rather than a fixed catalog order.
    static func sortedForDisplay(state: GameState) -> [AchievementDefinition] {
        AchievementCatalog.all.sorted { lhs, rhs in
            let lhsUnlocked = isUnlocked(lhs, state: state)
            let rhsUnlocked = isUnlocked(rhs, state: state)
            if lhsUnlocked != rhsUnlocked { return lhsUnlocked }
            if !lhsUnlocked {
                return progressFraction(lhs, state: state) > progressFraction(rhs, state: state)
            }
            return false
        }
    }

    private static func ownedCount<T>(_ items: [T], isOwned: (T) -> Bool) -> Int {
        items.filter(isOwned).count
    }

    private static func totalNoobLevels(state: GameState) -> Int {
        GeneratorCatalog.all.reduce(0) { $0 + GeneratorStore.level($1, state: state) }
    }

    private static func totalNoobLevels(state: GameState, zoneID: String) -> Int {
        GeneratorCatalog.all(inZone: zoneID).reduce(0) { $0 + GeneratorStore.level($1, state: state) }
    }

    /// Achievements whose condition is already met but aren't recorded as unlocked yet.
    static func newlyUnlockable(state: GameState) -> [AchievementDefinition] {
        AchievementCatalog.all.filter { !isUnlocked($0, state: state) && conditionMet($0, state: state) }
    }

    /// Records every newly-met achievement as unlocked. Returns the updated state plus
    /// exactly which ones were newly unlocked (for toast/celebration UI).
    static func unlockNewlyMet(state: GameState) -> (state: GameState, unlocked: [AchievementDefinition]) {
        let newly = newlyUnlockable(state: state)
        guard !newly.isEmpty else { return (state, []) }
        var next = state
        for definition in newly { next.unlockedAchievements.insert(definition.id) }
        return (next, newly)
    }

    static func outputMultiplier(state: GameState) -> Decimal {
        1 + Decimal(state.unlockedAchievements.count) * outputMultiplierPerAchievement
    }
}
