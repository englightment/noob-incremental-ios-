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

    func testExtendedRestUpgradeRaisesTheOfflineCap() {
        guard let extendedRest = RebirthUpgradeCatalog.definition(for: "rebirth_extended_rest") else {
            return XCTFail("rebirth_extended_rest missing from catalog")
        }
        let now = Date()
        var state = GameState.newGame
        state.rebirthCurrency = 1_000_000
        state = RebirthUpgradeStore.buyOne(extendedRest, state: state)
        // Long enough to exceed the base cap but stay within base + one level of the upgrade.
        state.lastSaveTimestamp = now.addingTimeInterval(-(GameBalance.maxOfflineProgressDuration + 3_600))

        let result = OfflineProgress.apply(to: state, now: now)

        XCTAssertGreaterThan(result.elapsedDuration, GameBalance.maxOfflineProgressDuration, "one level of Extended Rest should raise the cap above the base 8h")
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
