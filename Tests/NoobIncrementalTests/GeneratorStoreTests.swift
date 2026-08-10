import XCTest
@testable import NoobIncremental

final class GeneratorStoreTests: XCTestCase {

    private let hut = GeneratorDefinition(id: "test_hut", name: "Test Hut", baseCost: 10, baseOutput: 1, unlockThreshold: 0)

    func testCostEqualsBaseWhenNoneOwned() {
        let state = GameState.newGame
        XCTAssertEqual(GeneratorStore.cost(for: hut, state: state), 10)
    }

    func testCanAffordReflectsCurrency() {
        var state = GameState.newGame
        state.currency = 5
        XCTAssertFalse(GeneratorStore.canAfford(hut, state: state))

        state.currency = 10
        XCTAssertTrue(GeneratorStore.canAfford(hut, state: state))
    }

    func testBuyDeductsCostAndIncrementsOwned() {
        var state = GameState.newGame
        state.currency = 10

        state = GeneratorStore.buy(hut, state: state)

        XCTAssertEqual(state.currency, 0)
        XCTAssertEqual(GeneratorStore.level(hut, state: state), 1)
    }

    func testBuyMarksGeneratorUnlocked() {
        var state = GameState.newGame
        state.currency = 10

        state = GeneratorStore.buy(hut, state: state)

        XCTAssertEqual(state.generators[hut.id]?.isUnlocked, true)
    }

    func testBuyWithInsufficientFundsLeavesStateUnchanged() {
        var state = GameState.newGame
        state.currency = 5

        let result = GeneratorStore.buy(hut, state: state)

        XCTAssertEqual(result, state)
    }

    func testCostIncreasesAfterEachPurchase() {
        var state = GameState.newGame
        state.currency = 1_000_000

        let firstCost = GeneratorStore.cost(for: hut, state: state)
        state = GeneratorStore.buy(hut, state: state)
        let secondCost = GeneratorStore.cost(for: hut, state: state)

        XCTAssertGreaterThan(secondCost, firstCost)
    }

    func testRepeatedBuysAccumulateOwnedCount() {
        var state = GameState.newGame
        state.currency = 1_000_000

        for _ in 0..<5 {
            state = GeneratorStore.buy(hut, state: state)
        }

        XCTAssertEqual(GeneratorStore.level(hut, state: state), 5)
    }

    // MARK: - Bulk purchase

    func testBuyQuantityBuysExactlyRequestedAmountWhenAffordable() {
        var state = GameState.newGame
        state.currency = 1_000_000

        state = GeneratorStore.buyQuantity(hut, quantity: 7, state: state)

        XCTAssertEqual(GeneratorStore.level(hut, state: state), 7)
    }

    func testBuyQuantityChargesTheExactBulkCost() {
        var state = GameState.newGame
        state.currency = 1_000_000
        let expectedCost = Formulas.bulkLevelCost(base: hut.baseCost, owned: 0, quantity: 7)

        state = GeneratorStore.buyQuantity(hut, quantity: 7, state: state)

        XCTAssertEqual(state.currency, 1_000_000 - expectedCost)
    }

    func testBuyQuantityIsAllOrNothingWhenShort() {
        // Enough for 2 levels (10 + 11.5 = 21.5) but not the requested 10 — should buy
        // nothing at all rather than silently filling as many as affordable.
        var state = GameState.newGame
        state.currency = 25

        let result = GeneratorStore.buyQuantity(hut, quantity: 10, state: state)

        XCTAssertEqual(result, state)
        XCTAssertEqual(GeneratorStore.level(hut, state: result), 0)
    }

    func testCanAffordQuantityMatchesBuyQuantityOutcome() {
        var state = GameState.newGame
        state.currency = 25

        XCTAssertFalse(GeneratorStore.canAffordQuantity(hut, quantity: 10, state: state))
        XCTAssertTrue(GeneratorStore.canAffordQuantity(hut, quantity: 2, state: state))

        state = GeneratorStore.buyQuantity(hut, quantity: 2, state: state)
        XCTAssertEqual(GeneratorStore.level(hut, state: state), 2)
    }

    func testBuyQuantityZeroIsNoOp() {
        var state = GameState.newGame
        state.currency = 1_000_000
        let before = state

        state = GeneratorStore.buyQuantity(hut, quantity: 0, state: state)

        XCTAssertEqual(state, before)
    }

    func testBuyMaxBuysNothingWhenCannotAffordFirstLevel() {
        var state = GameState.newGame
        state.currency = 5

        state = GeneratorStore.buyMax(hut, state: state)

        XCTAssertEqual(GeneratorStore.level(hut, state: state), 0)
        XCTAssertEqual(state.currency, 5)
    }

    func testBuyMaxSpendsDownToWhatsLeftUnaffordable() {
        var state = GameState.newGame
        state.currency = 1_000

        state = GeneratorStore.buyMax(hut, state: state)

        XCTAssertFalse(GeneratorStore.canAfford(hut, state: state), "should have bought until the next level is unaffordable")
    }
}
