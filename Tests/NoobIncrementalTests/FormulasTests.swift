import XCTest
@testable import NoobIncremental

final class FormulasTests: XCTestCase {

    // MARK: - Leveled cost scaling

    func testLevelCostAtZeroOwnedEqualsBase() {
        let cost = Formulas.levelCost(base: 10, owned: 0, growthRate: 1.15)
        XCTAssertEqual(cost, 10)
    }

    func testLevelCostIncreasesMonotonicallyWithOwned() {
        var previous = Formulas.levelCost(base: 10, owned: 0, growthRate: 1.15)
        for owned in 1...20 {
            let current = Formulas.levelCost(base: 10, owned: owned, growthRate: 1.15)
            XCTAssertGreaterThan(current, previous, "cost should strictly increase at owned=\(owned)")
            previous = current
        }
    }

    func testLevelCostMatchesExpectedGrowthFormula() {
        // cost = base * growthRate^owned
        let cost = Formulas.levelCost(base: 100, owned: 5, growthRate: 1.15)
        let expected = 100.0 * pow(1.15, 5.0)
        let actual = NSDecimalNumber(decimal: cost).doubleValue
        XCTAssertEqual(actual, expected, accuracy: 0.01)
    }

    func testBulkLevelCostEqualsSumOfIndividualCosts() {
        let bulk = Formulas.bulkLevelCost(base: 10, owned: 3, quantity: 4, growthRate: 1.15)
        var manualSum: Decimal = 0
        for i in 0..<4 {
            manualSum += Formulas.levelCost(base: 10, owned: 3 + i, growthRate: 1.15)
        }
        XCTAssertEqual(bulk, manualSum)
    }

    func testBulkLevelCostZeroQuantityIsZero() {
        XCTAssertEqual(Formulas.bulkLevelCost(base: 10, owned: 0, quantity: 0), 0)
    }

    // MARK: - Generator output

    func testGeneratorOutputScalesWithOwnedCount() {
        let output = Formulas.generatorOutput(baseOutput: 1, owned: 5, outputMultiplier: 2)
        XCTAssertEqual(output, 10)
    }

    func testGeneratorOutputIsZeroWhenNoneOwned() {
        let output = Formulas.generatorOutput(baseOutput: 1, owned: 0, outputMultiplier: 2)
        XCTAssertEqual(output, 0)
    }

    // MARK: - Rebirth

    func testRebirthGainIsZeroBelowThreshold() {
        let gain = Formulas.rebirthGain(currency: 0, divisor: 10_000)
        XCTAssertEqual(gain, 0)
    }

    func testRebirthGainAtExactlyDivisorIsOne() {
        let gain = Formulas.rebirthGain(currency: 10_000, divisor: 10_000)
        let actual = NSDecimalNumber(decimal: gain).doubleValue
        XCTAssertEqual(actual, 1.0, accuracy: 0.0001)
    }

    func testRebirthGainQuadruplesWhenCurrencyQuadruples() {
        // gain = sqrt(currency / divisor), so 4x currency -> 2x gain
        let base = Formulas.rebirthGain(currency: 10_000, divisor: 10_000)
        let quadrupled = Formulas.rebirthGain(currency: 40_000, divisor: 10_000)
        let baseD = NSDecimalNumber(decimal: base).doubleValue
        let quadD = NSDecimalNumber(decimal: quadrupled).doubleValue
        XCTAssertEqual(quadD, baseD * 2, accuracy: 0.0001)
    }
}
