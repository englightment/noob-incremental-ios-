import XCTest
@testable import NoobIncremental

final class NumberFormattingTests: XCTestCase {

    func testSmallNumbersHaveNoSuffix() {
        XCTAssertEqual(NumberFormatting.format(5.0), "5.00")
        XCTAssertEqual(NumberFormatting.format(999.0), "999.0")
    }

    func testThousandsUseKSuffix() {
        XCTAssertEqual(NumberFormatting.format(1_200.0), "1.20K")
    }

    func testMillionsUseMSuffix() {
        XCTAssertEqual(NumberFormatting.format(3_450_000.0), "3.45M")
    }

    func testBillionsUseBSuffix() {
        XCTAssertEqual(NumberFormatting.format(1_000_000_000.0), "1.00B")
    }

    func testNegativeNumbersKeepSign() {
        XCTAssertEqual(NumberFormatting.format(-1_200.0), "-1.20K")
    }

    func testVeryLargeNumbersFallBackToScientificNotation() {
        let huge = pow(10.0, 100.0)
        let formatted = NumberFormatting.format(huge)
        XCTAssertTrue(formatted.contains("e"), "expected scientific notation, got \(formatted)")
    }
}
