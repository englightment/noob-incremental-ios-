import Foundation

/// Which worlds are unlocked. Only two zones exist so a direct mapping is simplest —
/// revisit with a data-driven requirement if a third zone gets added.
enum WorldSystem {
    static func isUnlocked(_ world: WorldDefinition, state: GameState) -> Bool {
        switch world.id {
        case WorldCatalog.zone1ID: return true
        case WorldCatalog.zone2ID: return state.rebirthCount >= 1
        default: return false
        }
    }
}
