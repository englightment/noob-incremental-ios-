import Foundation

/// Decides when it's a reasonable moment to ask for an App Store review — a well-earned
/// point in the session (first rebirth, a handful of achievements) rather than on cold
/// launch. The actual StoreKit call lives in the view layer (SwiftUI's
/// EnvironmentValues.requestReview needs a view context); this is just the pure "should we
/// ask" decision, kept separate so it's testable the same way OnboardingSystem is.
enum ReviewPromptSystem {
    static let minAchievementsToPrompt = 5

    static func shouldRequest(state: GameState) -> Bool {
        guard !state.hasRequestedReview else { return false }
        return state.rebirthCount >= 1 || state.unlockedAchievements.count >= minAchievementsToPrompt
    }
}
