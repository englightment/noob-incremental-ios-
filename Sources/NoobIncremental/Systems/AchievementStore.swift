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
        case .zone2NoobLevels(let total):
            return totalNoobLevels(state: state, zoneID: WorldCatalog.zone2ID) >= total
        case .allRunesOwned:
            return RuneCatalog.all.allSatisfy { RuneStore.level($0, state: state) > 0 }
        }
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
