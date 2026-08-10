import XCTest
@testable import NoobIncremental

final class MinionSystemTests: XCTestCase {

    private let firstMinion = MinionCatalog.all[0]
    private let secondMinion = MinionCatalog.all[1]

    func testNoMinionsOwnedOnNewGame() {
        let state = GameState.newGame
        XCTAssertFalse(MinionSystem.isOwned(firstMinion, state: state))
        XCTAssertEqual(MinionSystem.outputMultiplier(state: state), 1)
    }

    func testSyncOwnershipUnlocksMinionWhenAchievementAlreadyMet() {
        var state = GameState.newGame
        state.unlockedAchievements.insert(firstMinion.unlockAchievementID)

        let synced = MinionSystem.syncOwnership(state: state)

        XCTAssertTrue(MinionSystem.isOwned(firstMinion, state: synced))
        XCTAssertFalse(MinionSystem.isEquipped(firstMinion, state: synced))
    }

    func testSyncOwnershipIsIdempotent() {
        var state = GameState.newGame
        state.unlockedAchievements.insert(firstMinion.unlockAchievementID)

        let once = MinionSystem.syncOwnership(state: state)
        let twice = MinionSystem.syncOwnership(state: once)

        XCTAssertEqual(once, twice)
    }

    func testCannotToggleEquipWhenNotOwned() {
        let state = GameState.newGame
        let next = MinionSystem.toggleEquip(firstMinion, state: state)
        XCTAssertFalse(MinionSystem.isEquipped(firstMinion, state: next))
    }

    func testEquipAndUnequipTogglesState() {
        var state = GameState.newGame
        state.unlockedAchievements.insert(firstMinion.unlockAchievementID)
        state = MinionSystem.syncOwnership(state: state)

        state = MinionSystem.toggleEquip(firstMinion, state: state)
        XCTAssertTrue(MinionSystem.isEquipped(firstMinion, state: state))

        state = MinionSystem.toggleEquip(firstMinion, state: state)
        XCTAssertFalse(MinionSystem.isEquipped(firstMinion, state: state))
    }

    func testCannotEquipBeyondMax() {
        var state = GameState.newGame
        for definition in MinionCatalog.all {
            state.unlockedAchievements.insert(definition.unlockAchievementID)
        }
        state = MinionSystem.syncOwnership(state: state)

        for definition in MinionCatalog.all {
            state = MinionSystem.toggleEquip(definition, state: state)
        }

        XCTAssertEqual(MinionSystem.equippedCount(state: state), MinionSystem.maxEquipped)
        XCTAssertLessThan(MinionSystem.maxEquipped, MinionCatalog.all.count)
    }

    func testOutputMultiplierOnlyCountsEquippedMinions() {
        var state = GameState.newGame
        state.unlockedAchievements.insert(firstMinion.unlockAchievementID)
        state.unlockedAchievements.insert(secondMinion.unlockAchievementID)
        state = MinionSystem.syncOwnership(state: state)

        state = MinionSystem.toggleEquip(firstMinion, state: state)
        let expected = 1 + firstMinion.outputBonus
        XCTAssertEqual(MinionSystem.outputMultiplier(state: state), expected)

        state = MinionSystem.toggleEquip(secondMinion, state: state)
        let expectedBoth = (1 + firstMinion.outputBonus) * (1 + secondMinion.outputBonus)
        XCTAssertEqual(MinionSystem.outputMultiplier(state: state), expectedBoth)
    }
}
