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
}
