import Foundation

/// Which worlds are unlocked — purely a function of rebirth count against each world's
/// own requirement, so adding a new zone is just a new WorldCatalog entry.
enum WorldSystem {
    static func isUnlocked(_ world: WorldDefinition, state: GameState) -> Bool {
        state.rebirthCount >= world.rebirthRequirement
    }
}
