import XCTest
@testable import NoobIncremental

final class RebirthUpgradeStoreTests: XCTestCase {

    private let upgrade = UpgradeDefinition(id: "test_rebirth_upgrade", name: "Test", baseCost: 100, maxLevel: 3, effect: .outputMultiplier(doublingInterval: 1))

    func testLevelIsZeroByDefault() {
        let state = GameState.newGame
        XCTAssertEqual(RebirthUpgradeStore.level(upgrade, state: state), 0)
    }

    func testBuyOneSpendsRebirthCurrencyNotOof() {
        var state = GameState.newGame
        state.currency = 1_000_000
        state.rebirthCurrency = 100

        state = RebirthUpgradeStore.buyOne(upgrade, state: state)

        XCTAssertEqual(state.rebirthCurrency, 0)
        XCTAssertEqual(state.currency, 1_000_000, "Oof should be untouched by rebirth-shop purchases")
        XCTAssertEqual(RebirthUpgradeStore.level(upgrade, state: state), 1)
    }

    func testBuyOneWithInsufficientRebirthCurrencyLeavesStateUnchanged() {
        var state = GameState.newGame
        state.rebirthCurrency = 50

        let result = RebirthUpgradeStore.buyOne(upgrade, state: state)

        XCTAssertEqual(result, state)
    }

    func testBuyMaxStopsAtLevelCap() {
        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000

        state = RebirthUpgradeStore.buyMax(upgrade, state: state)

        XCTAssertEqual(RebirthUpgradeStore.level(upgrade, state: state), 3)
        XCTAssertTrue(RebirthUpgradeStore.isMaxed(upgrade, state: state))
    }

    // MARK: - Real catalog effects

    func testRebirthMoreOofDoublesEveryLevel() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_more_oof") else {
            return XCTFail("rebirth_more_oof missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000_000
        state = RebirthUpgradeStore.buyOne(def, state: state)
        state = RebirthUpgradeStore.buyOne(def, state: state)

        let multiplier = NSDecimalNumber(decimal: RebirthUpgradeStore.outputMultiplier(state: state)).doubleValue
        XCTAssertEqual(multiplier, 4.0, accuracy: 0.0001) // 2^2 levels
    }

    func testRebirthMoreRebirthCompoundsAtQuarterGrowthPerLevel() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_more_rebirth") else {
            return XCTFail("rebirth_more_rebirth missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000_000
        for _ in 0..<3 {
            state = RebirthUpgradeStore.buyOne(def, state: state)
        }

        let multiplier = NSDecimalNumber(decimal: RebirthUpgradeStore.rebirthGainMultiplier(state: state)).doubleValue
        XCTAssertEqual(multiplier, pow(1.25, 3.0), accuracy: 0.0001)
    }

    func testOutputMultiplierIsOneWithNoRebirthUpgrades() {
        let state = GameState.newGame
        XCTAssertEqual(RebirthUpgradeStore.outputMultiplier(state: state), 1)
    }

    func testRebirthGainMultiplierIsOneWithNoRebirthUpgrades() {
        let state = GameState.newGame
        XCTAssertEqual(RebirthUpgradeStore.rebirthGainMultiplier(state: state), 1)
    }

    func testRebirthSpeedIncreasesTickSpeedMultiplier() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_speed") else {
            return XCTFail("rebirth_speed missing from catalog")
        }
        XCTAssertEqual(RebirthUpgradeStore.tickSpeedMultiplier(state: .newGame), 1)

        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000_000
        state = RebirthUpgradeStore.buyOne(def, state: state)

        XCTAssertGreaterThan(RebirthUpgradeStore.tickSpeedMultiplier(state: state), 1)
    }

    func testRebirthMegaValueAddsFlatOutputBonus() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_mega_value") else {
            return XCTFail("rebirth_mega_value missing from catalog")
        }
        XCTAssertEqual(RebirthUpgradeStore.flatOutputBonus(state: .newGame), 0)

        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000_000
        for _ in 0..<2 {
            state = RebirthUpgradeStore.buyOne(def, state: state)
        }

        XCTAssertEqual(RebirthUpgradeStore.flatOutputBonus(state: state), 500 * 2)
    }

    func testExtraMinionSlotsAddsOnePerLevel() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_minion_slots") else {
            return XCTFail("rebirth_minion_slots missing from catalog")
        }
        XCTAssertEqual(RebirthUpgradeStore.minionSlotBonus(state: .newGame), 0)

        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000
        state = RebirthUpgradeStore.buyOne(def, state: state)

        XCTAssertEqual(RebirthUpgradeStore.minionSlotBonus(state: state), 1)
    }

    func testExtendedRestAddsTwoHoursPerLevel() {
        guard let def = RebirthUpgradeCatalog.definition(for: "rebirth_extended_rest") else {
            return XCTFail("rebirth_extended_rest missing from catalog")
        }
        XCTAssertEqual(RebirthUpgradeStore.offlineCapBonus(state: .newGame), 0)

        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000
        state = RebirthUpgradeStore.buyOne(def, state: state)

        XCTAssertEqual(RebirthUpgradeStore.offlineCapBonus(state: state), 2 * 3_600)
    }
}
