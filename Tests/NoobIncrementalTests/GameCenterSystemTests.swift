import XCTest
@testable import NoobIncremental

final class GameCenterSystemTests: XCTestCase {

    func testLeaderboardScoreIsZeroForNoProgress() {
        XCTAssertEqual(GameCenterSystem.leaderboardScore(lifetimeEarned: 0), 0)
    }

    func testLeaderboardScoreMatchesLifetimeEarnedWithinIntRange() {
        XCTAssertEqual(GameCenterSystem.leaderboardScore(lifetimeEarned: 1_000_000), 1_000_000)
    }

    func testLeaderboardScoreClampsRatherThanOverflowingPastIntMax() {
        // Lifetime Oof can grow far past Int.max at extreme late-game (Zone 4's priciest
        // Noob alone costs ~945 quadrillion, see #21/#23) - the score must clamp instead of
        // producing garbage from an out-of-range Decimal-to-Int conversion.
        let farBeyondIntMax: Decimal = Decimal(Int.max) * 1_000
        let score = GameCenterSystem.leaderboardScore(lifetimeEarned: farBeyondIntMax)
        XCTAssertEqual(score, Int.max)
    }
}
