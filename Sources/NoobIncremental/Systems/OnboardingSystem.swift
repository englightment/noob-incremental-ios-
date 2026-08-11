import Foundation

/// Drives the one-time first-launch tip. Deliberately doesn't gate on a flag alone — a save
/// that already has real progress is never a "first launch" regardless of what
/// `hasSeenOnboarding` says, which is what makes `backfillIfNeeded` safe to run against
/// every existing save the moment this feature ships.
enum OnboardingSystem {

    static func hasPlayedBefore(_ state: GameState) -> Bool {
        !state.generators.isEmpty || state.lifetimeEarned > 0 || state.rebirthCount > 0 || state.totalPlayTime > 0
    }

    static func shouldShowOnboarding(_ state: GameState) -> Bool {
        !state.hasSeenOnboarding && !hasPlayedBefore(state)
    }

    /// Call once right after loading a save. Silently marks any save with existing progress
    /// as having "seen" onboarding, so it can never resurface for a returning player just
    /// because this field didn't exist in their older save file.
    static func backfillIfNeeded(_ state: GameState) -> GameState {
        guard !state.hasSeenOnboarding, hasPlayedBefore(state) else { return state }
        var next = state
        next.hasSeenOnboarding = true
        return next
    }

    static func dismiss(_ state: GameState) -> GameState {
        var next = state
        next.hasSeenOnboarding = true
        return next
    }
}
