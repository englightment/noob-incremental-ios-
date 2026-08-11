import XCTest
@testable import NoobIncremental

final class GeneratorMilestoneSystemTests: XCTestCase {

    func testMultiplierIsOneBelowFirstThreshold() {
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 0), 1)
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 24), 1)
    }

    func testMultiplierDoublesAtEachThreshold() {
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 25), 2)
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 49), 2)
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 50), 4)
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: 100), 8)
    }

    func testMultiplierAtHighestThresholdMatchesThresholdCount() {
        let thresholds = GeneratorMilestoneSystem.thresholds
        let expected = Decimal(pow(2.0, Double(thresholds.count)))
        XCTAssertEqual(GeneratorMilestoneSystem.multiplier(level: thresholds.last!), expected)
    }

    func testNextThresholdReturnsFirstUncrossedLevel() {
        XCTAssertEqual(GeneratorMilestoneSystem.nextThreshold(level: 0), 25)
        XCTAssertEqual(GeneratorMilestoneSystem.nextThreshold(level: 25), 50)
        XCTAssertEqual(GeneratorMilestoneSystem.nextThreshold(level: 999), 1_000)
    }

    func testNextThresholdIsNilAfterAllCrossed() {
        XCTAssertNil(GeneratorMilestoneSystem.nextThreshold(level: GeneratorMilestoneSystem.thresholds.last!))
    }

    func testCrossedCountDetectsThresholdsPassedByABulkPurchase() {
        XCTAssertEqual(GeneratorMilestoneSystem.crossedCount(from: 20, to: 30), 1) // crosses 25
        XCTAssertEqual(GeneratorMilestoneSystem.crossedCount(from: 0, to: 60), 2) // crosses 25 and 50
        XCTAssertEqual(GeneratorMilestoneSystem.crossedCount(from: 30, to: 40), 0) // no threshold in (30, 40]
    }

    func testGameLoopAppliesMilestoneMultiplierToThatGeneratorOnly() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob"),
              let farmer = GeneratorCatalog.definition(for: "farmer_noob") else {
            return XCTFail("expected generators missing from catalog")
        }
        var state = GameState.newGame
        state.currency = 10_000_000
        state = GeneratorStore.buyQuantity(starter, quantity: 25, state: state) // crosses the first milestone
        state = GeneratorStore.buy(farmer, state: state) // stays below any milestone

        let expected = starter.baseOutput * 25 * 2 + farmer.baseOutput
        let actual = GameLoop.passiveIncomePerSecond(state)

        XCTAssertEqual(NSDecimalNumber(decimal: actual).doubleValue, NSDecimalNumber(decimal: expected).doubleValue, accuracy: 0.0001)
    }
}
