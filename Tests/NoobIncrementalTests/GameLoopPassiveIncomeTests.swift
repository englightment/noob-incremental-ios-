import XCTest
@testable import NoobIncremental

final class GameLoopPassiveIncomeTests: XCTestCase {

    func testPassiveIncomeIsZeroWithNoGeneratorsOwned() {
        let state = GameState.newGame
        XCTAssertEqual(GameLoop.passiveIncomePerSecond(state), 0)
    }

    func testPassiveIncomeReflectsOwnedGenerator() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)

        XCTAssertEqual(GameLoop.passiveIncomePerSecond(state), noob.baseOutput)
    }

    func testTickAddsPassiveIncomeOverElapsedTime() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        let currencyBeforeTick = state.currency

        let ticked = GameLoop.tick(state, elapsed: 10)

        let expectedGain = noob.baseOutput * 10
        XCTAssertEqual(ticked.currency, currencyBeforeTick + expectedGain)
        XCTAssertEqual(ticked.lifetimeEarned, state.lifetimeEarned + expectedGain)
    }

    func testTickWithZeroElapsedTimeIsNoOp() {
        let state = GameState.newGame
        let ticked = GameLoop.tick(state, elapsed: 0)
        XCTAssertEqual(ticked, state)
    }

    func testPassiveIncomeSumsAcrossMultipleGeneratorTypes() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob"),
              let farmer = GeneratorCatalog.definition(for: "farmer_noob") else {
            return XCTFail("expected generators missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(starter, state: state)
        state = GeneratorStore.buy(farmer, state: state)

        XCTAssertEqual(GameLoop.passiveIncomePerSecond(state), starter.baseOutput + farmer.baseOutput)
    }

    func testUpgradeOutputMultiplierAppliesToPassiveIncome() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob"),
              let moreOof = UpgradeCatalog.definition(for: "more_oof") else {
            return XCTFail("expected catalog entries missing")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = UpgradeStore.buyOne(moreOof, state: state)

        let expectedMultiplier = UpgradeEffect.outputMultiplierValue(level: 1, doublingInterval: 15)
        let expected = noob.baseOutput * expectedMultiplier
        let actual = GameLoop.passiveIncomePerSecond(state)

        XCTAssertEqual(NSDecimalNumber(decimal: actual).doubleValue, NSDecimalNumber(decimal: expected).doubleValue, accuracy: 0.0001)
    }

    func testTickSpeedReductionIncreasesOutputMultiplier() {
        // "faster_noobs" caps at maxLevel 5, so this also verifies the multiplier reflects
        // being maxed out: 5 levels * 0.1s = 0.5s reduction -> effective tick 0.5s -> multiplier 2.0.
        guard let fasterNoobs = UpgradeCatalog.definition(for: "faster_noobs") else {
            return XCTFail("faster_noobs missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = UpgradeStore.buyMax(fasterNoobs, state: state)

        XCTAssertTrue(UpgradeStore.isMaxed(fasterNoobs, state: state))
        let multiplier = UpgradeStore.tickSpeedMultiplier(state: state)
        XCTAssertEqual(NSDecimalNumber(decimal: multiplier).doubleValue, 2.0, accuracy: 0.001)
    }
}
