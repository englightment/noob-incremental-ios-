import XCTest
@testable import NoobIncremental

final class AdBoostSystemTests: XCTestCase {

    func testNotActiveWhenNeverGranted() {
        let state = GameState.newGame
        XCTAssertFalse(AdBoostSystem.isActive(.twoX, state: state))
        XCTAssertFalse(AdBoostSystem.isActive(.fourX, state: state))
        XCTAssertEqual(AdBoostSystem.combinedMultiplier(state: state), 1)
    }

    func testActiveImmediatelyAfterActivation() {
        let now = Date()
        let state = AdBoostSystem.activate(.twoX, state: .newGame, duration: 3600, now: now)

        XCTAssertTrue(AdBoostSystem.isActive(.twoX, state: state, now: now))
        XCTAssertEqual(AdBoostSystem.combinedMultiplier(state: state, now: now), 2)
    }

    func testInactiveAfterExpiry() {
        let now = Date()
        let state = AdBoostSystem.activate(.twoX, state: .newGame, duration: 3600, now: now)
        let later = now.addingTimeInterval(3601)

        XCTAssertFalse(AdBoostSystem.isActive(.twoX, state: state, now: later))
        XCTAssertEqual(AdBoostSystem.combinedMultiplier(state: state, now: later), 1)
    }

    func testRemainingSecondsCountsDownToZeroAtExpiry() {
        let now = Date()
        let state = AdBoostSystem.activate(.fourX, state: .newGame, duration: 3600, now: now)

        XCTAssertEqual(AdBoostSystem.remainingSeconds(.fourX, state: state, now: now), 3600, accuracy: 0.001)
        XCTAssertEqual(AdBoostSystem.remainingSeconds(.fourX, state: state, now: now.addingTimeInterval(3600)), 0, accuracy: 0.001)
        XCTAssertEqual(AdBoostSystem.remainingSeconds(.fourX, state: state, now: now.addingTimeInterval(4000)), 0)
    }

    func testBothTiersStackMultiplicatively() {
        let now = Date()
        var state = AdBoostSystem.activate(.twoX, state: .newGame, duration: 3600, now: now)
        state = AdBoostSystem.activate(.fourX, state: state, duration: 3600, now: now)

        XCTAssertTrue(AdBoostSystem.isActive(.twoX, state: state, now: now))
        XCTAssertTrue(AdBoostSystem.isActive(.fourX, state: state, now: now))
        XCTAssertEqual(AdBoostSystem.combinedMultiplier(state: state, now: now), 8)
    }

    func testTiersExpireIndependently() {
        let now = Date()
        var state = AdBoostSystem.activate(.twoX, state: .newGame, duration: 1800, now: now)
        state = AdBoostSystem.activate(.fourX, state: state, duration: 3600, now: now)
        let later = now.addingTimeInterval(1801)

        XCTAssertFalse(AdBoostSystem.isActive(.twoX, state: state, now: later))
        XCTAssertTrue(AdBoostSystem.isActive(.fourX, state: state, now: later))
        XCTAssertEqual(AdBoostSystem.combinedMultiplier(state: state, now: later), 4)
    }

    func testActivatingAgainExtendsExpiry() {
        let now = Date()
        var state = AdBoostSystem.activate(.twoX, state: .newGame, duration: 3600, now: now)
        let refreshTime = now.addingTimeInterval(1800)
        state = AdBoostSystem.activate(.twoX, state: state, duration: 3600, now: refreshTime)

        XCTAssertEqual(AdBoostSystem.remainingSeconds(.twoX, state: state, now: refreshTime), 3600, accuracy: 0.001)
    }
}
