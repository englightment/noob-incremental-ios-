import Foundation

/// Minions are unlocked for free by hitting their tied achievement (see MinionCatalog), then
/// equipped manually — only `maxEquipped` can be active at once, so which ones to run is a
/// real choice.
enum MinionSystem {

    private static let baseMaxEquipped = 3

    /// Base slot count plus whatever the "Extra Minion Slots" rebirth upgrade has granted.
    static func maxEquipped(state: GameState) -> Int {
        baseMaxEquipped + RebirthUpgradeStore.minionSlotBonus(state: state)
    }

    static func isOwned(_ definition: MinionDefinition, state: GameState) -> Bool {
        state.ownedMinions[definition.id]?.isUnlocked ?? false
    }

    static func isEquipped(_ definition: MinionDefinition, state: GameState) -> Bool {
        state.equippedMinionIDs.contains(definition.id)
    }

    static func equippedCount(state: GameState) -> Int {
        state.equippedMinionIDs.count
    }

    static func canEquipMore(state: GameState) -> Bool {
        equippedCount(state: state) < maxEquipped(state: state)
    }

    /// Marks any minion whose unlock achievement is already recorded as owned but not yet
    /// reflected in `ownedMinions`. Idempotent, safe to call after any achievement check.
    static func syncOwnership(state: GameState) -> GameState {
        var next = state
        for definition in MinionCatalog.all {
            guard state.unlockedAchievements.contains(definition.unlockAchievementID) else { continue }
            guard next.ownedMinions[definition.id]?.isUnlocked != true else { continue }
            next.ownedMinions[definition.id] = MinionState(id: definition.id, isUnlocked: true)
        }
        return next
    }

    static func toggleEquip(_ definition: MinionDefinition, state: GameState) -> GameState {
        guard isOwned(definition, state: state) else { return state }
        var next = state
        if next.equippedMinionIDs.contains(definition.id) {
            next.equippedMinionIDs.removeAll { $0 == definition.id }
        } else if canEquipMore(state: state) {
            next.equippedMinionIDs.append(definition.id)
        }
        return next
    }

    static func outputMultiplier(state: GameState) -> Decimal {
        MinionCatalog.all.reduce(Decimal(1)) { total, definition in
            guard isEquipped(definition, state: state) else { return total }
            return total * (1 + definition.outputBonus)
        }
    }
}
