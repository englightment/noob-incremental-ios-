import XCTest
@testable import NoobIncremental

final class OfflineProgressTests: XCTestCase {

    func testElapsedDurationMatchesRealGapWhenUnderCap() {
        let now = Date()
        var state = GameState.newGame
        state.lastSaveTimestamp = now.addingTimeInterval(-60) // 60s ago

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.elapsedDuration, 60, accuracy: 0.001)
    }

    func testElapsedDurationIsCappedAtMaxOfflineDuration() {
        let now = Date()
        var state = GameState.newGame
        state.lastSaveTimestamp = now.addingTimeInterval(-60 * 60 * 24 * 3) // 3 days ago

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.elapsedDuration, GameBalance.maxOfflineProgressDuration, accuracy: 0.001)
    }

    func testNegativeElapsedTimeIsClampedToZero() {
        let now = Date()
        var state = GameState.newGame
        state.lastSaveTimestamp = now.addingTimeInterval(60) // save timestamp in the future (clock skew)

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.elapsedDuration, 0)
    }

    func testLastSaveTimestampIsUpdatedToNow() {
        let now = Date()
        var state = GameState.newGame
        state.lastSaveTimestamp = now.addingTimeInterval(-120)

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.state.lastSaveTimestamp, now)
    }

    func testTotalPlayTimeAdvancesByCappedElapsed() {
        let now = Date()
        var state = GameState.newGame
        state.totalPlayTime = 0
        state.lastSaveTimestamp = now.addingTimeInterval(-30)

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.state.totalPlayTime, 30, accuracy: 0.001)
    }

    func testCurrencyEarnedMatchesDifferenceBeforeAndAfter() {
        let now = Date()
        var state = GameState.newGame
        state.currency = 50
        state.lastSaveTimestamp = now.addingTimeInterval(-100)

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertEqual(result.currencyEarned, result.state.currency - 50)
    }
}
