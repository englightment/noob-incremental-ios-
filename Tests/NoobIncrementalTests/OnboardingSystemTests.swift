import XCTest
@testable import NoobIncremental

final class OnboardingSystemTests: XCTestCase {

    func testShowsOnboardingForABrandNewGame() {
        let state = GameState.newGame
        XCTAssertTrue(OnboardingSystem.shouldShowOnboarding(state))
    }

    func testDismissMarksOnboardingAsSeen() {
        let state = GameState.newGame
        let dismissed = OnboardingSystem.dismiss(state)

        XCTAssertTrue(dismissed.hasSeenOnboarding)
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(dismissed))
    }

    func testDoesNotShowOnboardingOnceThereIsRealProgress() {
        var state = GameState.newGame
        state.generators = ["starter_noob": GeneratorState(id: "starter_noob", level: 1)]
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(state), "owning a generator means this isn't a first launch")

        state = GameState.newGame
        state.lifetimeEarned = 1
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(state))

        state = GameState.newGame
        state.rebirthCount = 1
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(state))

        state = GameState.newGame
        state.totalPlayTime = 1
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(state))
    }

    func testBackfillMarksExistingProgressAsSeenWithoutShowingOnboarding() {
        // Simulates a save from before this feature existed: hasSeenOnboarding defaults to
        // false (missing key), but the player clearly isn't new.
        var oldSave = GameState.newGame
        oldSave.lifetimeEarned = 500_000
        oldSave.rebirthCount = 3
        XCTAssertFalse(oldSave.hasSeenOnboarding, "precondition: simulating a pre-existing save")

        let backfilled = OnboardingSystem.backfillIfNeeded(oldSave)

        XCTAssertTrue(backfilled.hasSeenOnboarding)
        XCTAssertFalse(OnboardingSystem.shouldShowOnboarding(backfilled))
    }

    func testBackfillLeavesATrulyFreshSaveUntouched() {
        let fresh = GameState.newGame
        let result = OnboardingSystem.backfillIfNeeded(fresh)

        XCTAssertFalse(result.hasSeenOnboarding, "a genuinely new save should still see onboarding")
        XCTAssertTrue(OnboardingSystem.shouldShowOnboarding(result))
    }

    func testBackfillIsIdempotent() {
        var state = GameState.newGame
        state.lifetimeEarned = 100
        let once = OnboardingSystem.backfillIfNeeded(state)
        let twice = OnboardingSystem.backfillIfNeeded(once)

        XCTAssertEqual(once, twice)
    }
}
