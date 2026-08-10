import XCTest
@testable import NoobIncremental

final class AutoBuyStoreTests: XCTestCase {

    func testNoOpWhenDisabled() {
        var state = GameState.newGame
        state.currency = 1_000_000
        state.autoBuyEnabled = false

        let result = AutoBuyStore.step(state: state)

        XCTAssertEqual(result, state)
    }

    func testNoOpWhenNothingAffordable() {
        var state = GameState.newGame
        state.currency = 0
        state.autoBuyEnabled = true

        let result = AutoBuyStore.step(state: state)

        XCTAssertEqual(result, state)
    }

    func testBuysCheapestAffordableVisibleGenerator() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        var state = GameState.newGame
        state.currency = starter.baseCost
        state.autoBuyEnabled = true

        let result = AutoBuyStore.step(state: state)

        XCTAssertEqual(GeneratorStore.level(starter, state: result), 1)
    }

    func testStepOnlyBuysOneLevelAtATime() {
        var state = GameState.newGame
        state.currency = 1_000_000
        state.autoBuyEnabled = true

        let afterOneStep = AutoBuyStore.step(state: state)
        let totalAfterOne = GeneratorCatalog.all.reduce(0) { $0 + GeneratorStore.level($1, state: afterOneStep) }

        XCTAssertEqual(totalAfterOne, 1)
    }

    func testRepeatedStepsEventuallyExhaustAffordablePurchases() {
        var state = GameState.newGame
        state.currency = 500
        state.autoBuyEnabled = true

        var previous = state
        for _ in 0..<1_000 {
            let next = AutoBuyStore.step(state: previous)
            if next == previous { break }
            previous = next
        }

        // Confirms the loop actually terminates (nothing left affordable) rather than looping forever.
        XCTAssertEqual(AutoBuyStore.step(state: previous), previous)
    }
}
