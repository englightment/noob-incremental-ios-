import XCTest
@testable import NoobIncremental

final class RebirthSystemTests: XCTestCase {

    func testCannotRebirthBelowRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement - 1
        XCTAssertFalse(RebirthSystem.canRebirth(state: state))
    }

    func testCanRebirthAtRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        XCTAssertTrue(RebirthSystem.canRebirth(state: state))
    }

    func testAvailableGainIsZeroBelowRequirement() {
        var state = GameState.newGame
        state.currency = 5
        XCTAssertEqual(RebirthSystem.availableGain(state: state), 0)
    }

    func testAvailableGainIsPositiveAtRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        XCTAssertGreaterThan(RebirthSystem.availableGain(state: state), 0)
    }

    func testPerformRebirthBelowRequirementLeavesStateUnchanged() {
        var state = GameState.newGame
        state.currency = 5

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(result, state)
    }

    func testPerformRebirthGrantsRebirthCurrencyAndIncrementsCount() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertGreaterThan(result.rebirthCurrency, 0)
        XCTAssertEqual(result.rebirthCount, 1)
    }

    func testPerformRebirthResetsOofOofUpgradesAndNoobs() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob"),
              let moreOof = UpgradeCatalog.definition(for: "more_oof") else {
            return XCTFail("expected catalog entries missing")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement + 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = UpgradeStore.buyOne(moreOof, state: state)

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(result.currency, GameBalance.startingCurrency)
        XCTAssertTrue(result.generators.isEmpty)
        XCTAssertTrue(result.upgradeLevels.isEmpty)
    }

    func testPerformRebirthPreservesExistingRebirthCurrencyAndUpgrades() {
        guard let rebirthMoreOof = RebirthUpgradeCatalog.definition(for: "rebirth_more_oof") else {
            return XCTFail("rebirth_more_oof missing from catalog")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        state.rebirthCurrency = 20_000
        state = RebirthUpgradeStore.buyOne(rebirthMoreOof, state: state)
        let rebirthUpgradeLevelBefore = RebirthUpgradeStore.level(rebirthMoreOof, state: state)
        XCTAssertEqual(rebirthUpgradeLevelBefore, 1, "precondition: purchase should have succeeded")

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(RebirthUpgradeStore.level(rebirthMoreOof, state: result), rebirthUpgradeLevelBefore)
        XCTAssertGreaterThan(result.rebirthCurrency, 0) // leftover balance plus this rebirth's gain
    }
}
