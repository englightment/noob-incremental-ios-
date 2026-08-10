import XCTest
@testable import NoobIncremental

final class RuneStoreTests: XCTestCase {

    private let rune = UpgradeDefinition(id: "test_rune", name: "Test Rune", baseCost: 5, maxLevel: 3, effect: .outputMultiplier(doublingInterval: 3))

    func testLevelIsZeroByDefault() {
        let state = GameState.newGame
        XCTAssertEqual(RuneStore.level(rune, state: state), 0)
    }

    func testBuyOneSpendsRuneShardsNotOofOrRebirthCurrency() {
        var state = GameState.newGame
        state.currency = 1_000_000
        state.rebirthCurrency = 1_000_000
        state.runeShards = 5

        state = RuneStore.buyOne(rune, state: state)

        XCTAssertEqual(state.runeShards, 0)
        XCTAssertEqual(state.currency, 1_000_000)
        XCTAssertEqual(state.rebirthCurrency, 1_000_000)
        XCTAssertEqual(RuneStore.level(rune, state: state), 1)
    }

    func testBuyOneWithInsufficientShardsLeavesStateUnchanged() {
        var state = GameState.newGame
        state.runeShards = 2

        let result = RuneStore.buyOne(rune, state: state)

        XCTAssertEqual(result, state)
    }

    func testBuyMaxStopsAtLevelCap() {
        var state = GameState.newGame
        state.runeShards = 1_000_000

        state = RuneStore.buyMax(rune, state: state)

        XCTAssertEqual(RuneStore.level(rune, state: state), 3)
        XCTAssertTrue(RuneStore.isMaxed(rune, state: state))
    }

    // MARK: - Real catalog effects

    func testRuneOfOofAppliesOutputMultiplier() {
        guard let runeOof = RuneCatalog.definition(for: "rune_oof") else {
            return XCTFail("rune_oof missing from catalog")
        }
        var state = GameState.newGame
        state.runeShards = 1_000_000
        state = RuneStore.buyOne(runeOof, state: state)

        XCTAssertGreaterThan(RuneStore.outputMultiplier(state: state), 1)
    }

    func testRuneOfRebirthAppliesRebirthGainMultiplier() {
        guard let runeRebirth = RuneCatalog.definition(for: "rune_rebirth") else {
            return XCTFail("rune_rebirth missing from catalog")
        }
        var state = GameState.newGame
        state.runeShards = 1_000_000
        state = RuneStore.buyOne(runeRebirth, state: state)

        XCTAssertGreaterThan(RuneStore.rebirthGainMultiplier(state: state), 1)
    }

    func testRuneOfHasteAppliesTickSpeedMultiplier() {
        guard let runeHaste = RuneCatalog.definition(for: "rune_haste") else {
            return XCTFail("rune_haste missing from catalog")
        }
        var state = GameState.newGame
        state.runeShards = 1_000_000
        state = RuneStore.buyOne(runeHaste, state: state)

        XCTAssertGreaterThan(RuneStore.tickSpeedMultiplier(state: state), 1)
    }

    func testAllMultipliersAreOneWithNoRunes() {
        let state = GameState.newGame
        XCTAssertEqual(RuneStore.outputMultiplier(state: state), 1)
        XCTAssertEqual(RuneStore.rebirthGainMultiplier(state: state), 1)
        XCTAssertEqual(RuneStore.tickSpeedMultiplier(state: state), 1)
    }

    func testRunesSurviveRebirth() {
        guard let runeOof = RuneCatalog.definition(for: "rune_oof") else {
            return XCTFail("rune_oof missing from catalog")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        state.runeShards = 1_000_000
        state = RuneStore.buyOne(runeOof, state: state)
        let levelBefore = RuneStore.level(runeOof, state: state)

        let afterRebirth = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(RuneStore.level(runeOof, state: afterRebirth), levelBefore)
    }
}
