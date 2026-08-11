import XCTest
@testable import NoobIncremental

final class DailyStreakSystemTests: XCTestCase {

    func testCanClaimOnFirstEverLaunch() {
        let state = GameState.newGame
        XCTAssertTrue(DailyStreakSystem.canClaim(state: state))
    }

    func testCannotClaimTwiceOnSameDay() {
        // Pinned to noon rather than Date() + a fixed offset — otherwise this test is flaky
        // whenever CI happens to run within 3 hours of midnight UTC, since "+3 hours" can
        // silently land on the next calendar day and flip the expected result.
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        var state = GameState.newGame
        state.lastStreakClaimDate = now

        XCTAssertFalse(DailyStreakSystem.canClaim(state: state, now: now.addingTimeInterval(60 * 60 * 3)))
    }

    func testCanClaimAgainTheNextCalendarDay() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        var state = GameState.newGame
        state.lastStreakClaimDate = now

        XCTAssertTrue(DailyStreakSystem.canClaim(state: state, now: tomorrow))
    }

    func testFirstClaimStartsStreakAtOne() {
        let state = GameState.newGame
        let result = DailyStreakSystem.claim(state: state)
        XCTAssertEqual(result?.state.currentStreak, 1)
    }

    func testConsecutiveDayClaimIncrementsStreak() {
        let calendar = Calendar.current
        let now = Date()
        var state = GameState.newGame
        state.currentStreak = 3
        state.lastStreakClaimDate = now

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let result = DailyStreakSystem.claim(state: state, now: tomorrow)

        XCTAssertEqual(result?.state.currentStreak, 4)
    }

    func testMissedDayResetsStreakToOne() {
        let calendar = Calendar.current
        let now = Date()
        var state = GameState.newGame
        state.currentStreak = 10
        state.lastStreakClaimDate = now

        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: now)!
        let result = DailyStreakSystem.claim(state: state, now: threeDaysLater)

        XCTAssertEqual(result?.state.currentStreak, 1)
    }

    func testLongestStreakTracksThePeak() {
        let calendar = Calendar.current
        let now = Date()
        var state = GameState.newGame
        state.currentStreak = 10
        state.longestStreak = 10
        state.lastStreakClaimDate = now

        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: now)! // breaks the streak
        let result = DailyStreakSystem.claim(state: state, now: threeDaysLater)

        XCTAssertEqual(result?.state.currentStreak, 1)
        XCTAssertEqual(result?.state.longestStreak, 10, "longest streak shouldn't drop just because the current one reset")
    }

    func testClaimingWhenAlreadyClaimedTodayReturnsNil() {
        let now = Date()
        var state = GameState.newGame
        state.lastStreakClaimDate = now

        let result = DailyStreakSystem.claim(state: state, now: now.addingTimeInterval(60))

        XCTAssertNil(result)
    }

    func testClaimGrantsTheRewardForThatStreakDay() {
        let state = GameState.newGame
        let startingCurrency = state.currency

        let result = DailyStreakSystem.claim(state: state)

        let expectedReward = DailyRewardCatalog.reward(forStreak: 1)
        XCTAssertEqual(result?.reward.day, expectedReward.day)
        XCTAssertEqual(result?.state.currency, startingCurrency + expectedReward.oof)
    }

    func testClaimGrantsRuneShardsOnDaysThatOfferThem() {
        let calendar = Calendar.current
        let now = Date()
        var state = GameState.newGame
        state.currentStreak = 8
        state.lastStreakClaimDate = now
        let startingRuneShards = state.runeShards

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let result = DailyStreakSystem.claim(state: state, now: tomorrow)

        let expectedReward = DailyRewardCatalog.reward(forStreak: 9)
        XCTAssertGreaterThan(expectedReward.runeShards, 0, "precondition: day 9 should offer Rune Shards")
        XCTAssertEqual(result?.state.runeShards, startingRuneShards + expectedReward.runeShards)
    }

    func testRewardCycleWrapsAfterFourteenDays() {
        let cycleLength = DailyRewardCatalog.cycle.count
        XCTAssertEqual(DailyRewardCatalog.reward(forStreak: 1).day, DailyRewardCatalog.reward(forStreak: 1 + cycleLength).day)
        XCTAssertEqual(DailyRewardCatalog.reward(forStreak: cycleLength).day, DailyRewardCatalog.reward(forStreak: cycleLength * 2).day)
    }

    func testAllFourteenDaysAreDistinctBeforeWrapping() {
        let cycleLength = DailyRewardCatalog.cycle.count
        let days = (1...cycleLength).map { DailyRewardCatalog.reward(forStreak: $0).day }
        XCTAssertEqual(Set(days).count, cycleLength, "every streak day in one cycle should map to a distinct reward")
    }
}
