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

    func testAchievementBonusAppliesToPassiveIncome() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state.unlockedAchievements = ["a", "b"] // +2% each = x1.04

        let expected = noob.baseOutput * (1 + 2 * AchievementStore.outputMultiplierPerAchievement)
        let actual = GameLoop.passiveIncomePerSecond(state)

        XCTAssertEqual(NSDecimalNumber(decimal: actual).doubleValue, NSDecimalNumber(decimal: expected).doubleValue, accuracy: 0.0001)
    }

    func testActiveLuckySurgeBoostMultipliesPassiveIncome() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        let now = Date()
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = BoostSystem.start(state: state, multiplier: 5, duration: 20, now: now)

        let boosted = GameLoop.passiveIncomePerSecond(state, now: now)
        let expired = GameLoop.passiveIncomePerSecond(state, now: now.addingTimeInterval(21))

        XCTAssertEqual(NSDecimalNumber(decimal: boosted).doubleValue, NSDecimalNumber(decimal: noob.baseOutput * 5).doubleValue, accuracy: 0.0001)
        XCTAssertEqual(NSDecimalNumber(decimal: expired).doubleValue, NSDecimalNumber(decimal: noob.baseOutput).doubleValue, accuracy: 0.0001)
    }

    func testRuneOfOofAppliesToPassiveIncome() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob"),
              let runeOof = RuneCatalog.definition(for: "rune_oof") else {
            return XCTFail("expected catalog entries missing")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state.runeShards = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = RuneStore.buyOne(runeOof, state: state)

        let withRune = GameLoop.passiveIncomePerSecond(state)
        XCTAssertGreaterThan(withRune, noob.baseOutput)
    }

    func testFlatOutputBonusAddsOnTopOfMultipliedGeneratorOutput() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob"),
              let noobValue = UpgradeCatalog.definition(for: "noob_value") else {
            return XCTFail("expected catalog entries missing")
        }
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = UpgradeStore.buyOne(noobValue, state: state)

        let expected = noob.baseOutput + UpgradeEffect.flatOutputBonusValue(level: 1, perLevel: 5)
        let actual = GameLoop.passiveIncomePerSecond(state)

        XCTAssertEqual(NSDecimalNumber(decimal: actual).doubleValue, NSDecimalNumber(decimal: expected).doubleValue, accuracy: 0.0001)
    }
}
