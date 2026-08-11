import XCTest
@testable import NoobIncremental

final class ShareSummaryTests: XCTestCase {

    func testTextIncludesLifetimeEarnedRebirthsAndAchievementCounts() {
        var state = GameState.newGame
        let earned: Decimal = 1_000_000
        state.lifetimeEarned = earned
        state.rebirthCount = 3
        state.unlockedAchievements = ["first_noob", "ten_levels"]

        let text = ShareSummary.text(state: state)

        XCTAssertTrue(text.contains(NumberFormatting.format(earned)))
        XCTAssertTrue(text.contains("3 rebirths"))
        XCTAssertTrue(text.contains("2/\(AchievementCatalog.all.count) achievements"))
    }

    func testTextForABrandNewGameStillProducesReadableCopy() {
        let text = ShareSummary.text(state: .newGame)
        XCTAssertTrue(text.contains("0 rebirths"))
        XCTAssertTrue(text.contains("0/\(AchievementCatalog.all.count) achievements"))
    }
}
