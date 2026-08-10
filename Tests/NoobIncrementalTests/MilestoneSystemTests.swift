import XCTest
@testable import NoobIncremental

final class MilestoneSystemTests: XCTestCase {

    func testTierIsZeroBelowFirstMilestone() {
        XCTAssertEqual(MilestoneSystem.tier(for: 99), 0)
    }

    func testTierOneAtOneHundred() {
        XCTAssertEqual(MilestoneSystem.tier(for: 100), 1)
    }

    func testTierIncreasesByOnePerPowerOfTen() {
        XCTAssertEqual(MilestoneSystem.tier(for: 1_000), 2)
        XCTAssertEqual(MilestoneSystem.tier(for: 10_000), 3)
        XCTAssertEqual(MilestoneSystem.tier(for: 100_000), 4)
    }

    func testThresholdRoundTripsWithTier() {
        for tier in 1...5 {
            let threshold = MilestoneSystem.threshold(forTier: tier)
            XCTAssertEqual(MilestoneSystem.tier(for: threshold), tier)
        }
    }

    func testHasNewMilestoneWhenTierExceedsCelebrated() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000
        state.highestMilestoneCelebrated = 0
        XCTAssertTrue(MilestoneSystem.hasNewMilestone(state: state))
    }

    func testNoNewMilestoneWhenAlreadyCelebrated() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000
        state.highestMilestoneCelebrated = MilestoneSystem.tier(for: 1_000)
        XCTAssertFalse(MilestoneSystem.hasNewMilestone(state: state))
    }

    func testCelebrateRecordsCurrentTier() {
        var state = GameState.newGame
        state.lifetimeEarned = 10_000

        state = MilestoneSystem.celebrate(state: state)

        XCTAssertEqual(state.highestMilestoneCelebrated, MilestoneSystem.tier(for: 10_000))
        XCTAssertFalse(MilestoneSystem.hasNewMilestone(state: state))
    }

    func testCelebrateIsNoOpWhenNoNewMilestone() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000
        state.highestMilestoneCelebrated = MilestoneSystem.tier(for: 1_000)
        let before = state

        state = MilestoneSystem.celebrate(state: state)

        XCTAssertEqual(state, before)
    }
}
