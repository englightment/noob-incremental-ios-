import XCTest
@testable import NoobIncremental

final class BoostSystemTests: XCTestCase {

    func testNotActiveWhenNoBoostStarted() {
        let state = GameState.newGame
        XCTAssertFalse(BoostSystem.isActive(state: state))
        XCTAssertEqual(BoostSystem.activeMultiplier(state: state), 1)
    }

    func testActiveImmediatelyAfterStart() {
        let now = Date()
        let state = BoostSystem.start(state: .newGame, multiplier: 5, duration: 20, now: now)

        XCTAssertTrue(BoostSystem.isActive(state: state, now: now))
        XCTAssertEqual(BoostSystem.activeMultiplier(state: state, now: now), 5)
    }

    func testInactiveAfterExpiry() {
        let now = Date()
        let state = BoostSystem.start(state: .newGame, multiplier: 5, duration: 20, now: now)
        let later = now.addingTimeInterval(21)

        XCTAssertFalse(BoostSystem.isActive(state: state, now: later))
        XCTAssertEqual(BoostSystem.activeMultiplier(state: state, now: later), 1)
    }

    func testRemainingSecondsCountsDownToZeroAtExpiry() {
        let now = Date()
        let state = BoostSystem.start(state: .newGame, multiplier: 5, duration: 20, now: now)

        XCTAssertEqual(BoostSystem.remainingSeconds(state: state, now: now), 20, accuracy: 0.001)
        XCTAssertEqual(BoostSystem.remainingSeconds(state: state, now: now.addingTimeInterval(20)), 0, accuracy: 0.001)
        XCTAssertEqual(BoostSystem.remainingSeconds(state: state, now: now.addingTimeInterval(25)), 0)
    }
}
