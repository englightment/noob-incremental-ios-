import XCTest
@testable import NoobIncremental

final class RedeemCodeStoreTests: XCTestCase {

    func testValidCodeGrantsReward() {
        let state = GameState.newGame
        let startingCurrency = state.currency

        let (newState, result) = RedeemCodeStore.redeem("WELCOME", state: state)

        guard case .success(let definition) = result else {
            return XCTFail("expected success, got \(result)")
        }
        XCTAssertEqual(definition.code, "WELCOME")
        XCTAssertEqual(newState.currency, startingCurrency + definition.rewardOof)
    }

    func testCodeMatchingIsCaseInsensitiveAndTrimsWhitespace() {
        let state = GameState.newGame
        let (_, result) = RedeemCodeStore.redeem("  welcome  ", state: state)
        guard case .success = result else {
            return XCTFail("expected success, got \(result)")
        }
    }

    func testInvalidCodeReturnsInvalidAndLeavesStateUnchanged() {
        let state = GameState.newGame
        let (newState, result) = RedeemCodeStore.redeem("NOT_A_REAL_CODE", state: state)
        XCTAssertEqual(result, .invalid)
        XCTAssertEqual(newState, state)
    }

    func testRedeemingTheSameCodeTwiceFailsTheSecondTime() {
        let state = GameState.newGame
        let (afterFirst, firstResult) = RedeemCodeStore.redeem("WELCOME", state: state)
        guard case .success = firstResult else {
            return XCTFail("expected first redemption to succeed")
        }

        let (afterSecond, secondResult) = RedeemCodeStore.redeem("WELCOME", state: afterFirst)

        XCTAssertEqual(secondResult, .alreadyRedeemed)
        XCTAssertEqual(afterSecond, afterFirst)
    }

    func testRedeemedCodeIsRecorded() {
        let state = GameState.newGame
        let (newState, _) = RedeemCodeStore.redeem("NOOBS", state: state)
        XCTAssertTrue(newState.redeemedCodes.contains("NOOBS"))
    }

    func testRebirthRewardCodeGrantsRebirthCurrency() {
        let state = GameState.newGame
        let (newState, result) = RedeemCodeStore.redeem("NOOBS", state: state)
        guard case .success(let definition) = result else {
            return XCTFail("expected success, got \(result)")
        }
        XCTAssertEqual(newState.rebirthCurrency, definition.rewardRebirth)
    }

    func testVoidCodeExistsAsZone4CelebrationBonus() {
        guard let definition = RedeemCodeCatalog.definition(for: "VOID") else {
            return XCTFail("VOID code missing from catalog")
        }
        XCTAssertGreaterThan(definition.rewardRebirth, 0)
    }
}
