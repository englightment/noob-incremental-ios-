import XCTest
@testable import NoobIncremental

final class UpgradeStoreTests: XCTestCase {

    private let upgrade = UpgradeDefinition(id: "test_upgrade", name: "Test Upgrade", baseCost: 10, maxLevel: 3, effect: .outputMultiplier(doublingInterval: 15))

    func testLevelIsZeroByDefault() {
        let state = GameState.newGame
        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 0)
    }

    func testCostEqualsBaseAtLevelZero() {
        let state = GameState.newGame
        XCTAssertEqual(UpgradeStore.cost(for: upgrade, state: state), 10)
    }

    func testBuyOneDeductsCostAndIncrementsLevel() {
        var state = GameState.newGame
        state.currency = 10

        state = UpgradeStore.buyOne(upgrade, state: state)

        XCTAssertEqual(state.currency, 0)
        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 1)
    }

    func testBuyOneWithInsufficientFundsLeavesStateUnchanged() {
        var state = GameState.newGame
        state.currency = 5

        let result = UpgradeStore.buyOne(upgrade, state: state)

        XCTAssertEqual(result, state)
    }

    func testIsMaxedAtMaxLevel() {
        var state = GameState.newGame
        state.currency = 1_000_000
        for _ in 0..<3 {
            state = UpgradeStore.buyOne(upgrade, state: state)
        }

        XCTAssertTrue(UpgradeStore.isMaxed(upgrade, state: state))
        XCTAssertFalse(UpgradeStore.canAfford(upgrade, state: state))
    }

    func testBuyOneBeyondMaxLevelIsNoOp() {
        var state = GameState.newGame
        state.currency = 1_000_000
        for _ in 0..<3 {
            state = UpgradeStore.buyOne(upgrade, state: state)
        }
        let maxedState = state

        state = UpgradeStore.buyOne(upgrade, state: state)

        XCTAssertEqual(state, maxedState)
        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 3)
    }

    func testBuyMaxStopsAtLevelCapNotAtAffordability() {
        var state = GameState.newGame
        state.currency = 1_000_000

        state = UpgradeStore.buyMax(upgrade, state: state)

        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 3)
    }

    func testBuyMaxStopsWhenUnaffordable() {
        var state = GameState.newGame
        state.currency = 10 // exactly one level's cost, growth rate makes level 2 unaffordable

        state = UpgradeStore.buyMax(upgrade, state: state)

        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 1)
    }

    func testBuyMaxWithNoCurrencyDoesNothing() {
        var state = GameState.newGame
        state.currency = 0

        state = UpgradeStore.buyMax(upgrade, state: state)

        XCTAssertEqual(UpgradeStore.level(upgrade, state: state), 0)
        XCTAssertEqual(state.currency, 0)
    }

    // MARK: - Aggregate multipliers

    func testOutputMultiplierIsOneWithNoUpgrades() {
        let state = GameState.newGame
        XCTAssertEqual(UpgradeStore.outputMultiplier(state: state), 1)
    }

    func testOutputMultiplierDoublesAtDoublingInterval() {
        guard let moreOof = UpgradeCatalog.definition(for: "more_oof") else {
            return XCTFail("more_oof missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        for _ in 0..<15 {
            state = UpgradeStore.buyOne(moreOof, state: state)
        }

        let multiplier = NSDecimalNumber(decimal: UpgradeStore.outputMultiplier(state: state)).doubleValue
        XCTAssertEqual(multiplier, 2.0, accuracy: 0.0001)
    }

    func testTickSpeedMultiplierIsOneWithNoUpgrades() {
        let state = GameState.newGame
        XCTAssertEqual(UpgradeStore.tickSpeedMultiplier(state: state), 1)
    }

    func testTickSpeedMultiplierIncreasesWithFasterNoobsLevels() {
        guard let fasterNoobs = UpgradeCatalog.definition(for: "faster_noobs") else {
            return XCTFail("faster_noobs missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = UpgradeStore.buyOne(fasterNoobs, state: state)

        XCTAssertGreaterThan(UpgradeStore.tickSpeedMultiplier(state: state), 1)
    }
}
