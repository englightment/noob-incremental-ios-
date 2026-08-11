import XCTest
@testable import NoobIncremental

final class ReviewPromptSystemTests: XCTestCase {

    func testShouldNotRequestForABrandNewGame() {
        XCTAssertFalse(ReviewPromptSystem.shouldRequest(state: .newGame))
    }

    func testShouldRequestAfterFirstRebirth() {
        var state = GameState.newGame
        state.rebirthCount = 1
        XCTAssertTrue(ReviewPromptSystem.shouldRequest(state: state))
    }

    func testShouldRequestAfterEnoughAchievements() {
        var state = GameState.newGame
        state.unlockedAchievements = Set((0..<ReviewPromptSystem.minAchievementsToPrompt).map { "achievement_\($0)" })
        XCTAssertTrue(ReviewPromptSystem.shouldRequest(state: state))
    }

    func testShouldNotRequestBelowTheAchievementThreshold() {
        var state = GameState.newGame
        state.unlockedAchievements = Set((0..<(ReviewPromptSystem.minAchievementsToPrompt - 1)).map { "achievement_\($0)" })
        XCTAssertFalse(ReviewPromptSystem.shouldRequest(state: state))
    }

    func testShouldNotRequestTwiceOnceAlreadyRequested() {
        var state = GameState.newGame
        state.rebirthCount = 5
        state.hasRequestedReview = true
        XCTAssertFalse(ReviewPromptSystem.shouldRequest(state: state))
    }
}
