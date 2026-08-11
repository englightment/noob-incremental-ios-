import Foundation

/// Builds the plain-text summary shared via ShareLink's Stats-section "Share Progress"
/// button. Kept as a pure (state) -> String function so the wording is testable without a
/// view.
enum ShareSummary {
    static func text(state: GameState) -> String {
        let earned = NumberFormatting.format(state.lifetimeEarned)
        let achievements = state.unlockedAchievements.count
        let totalAchievements = AchievementCatalog.all.count
        return "I've earned \(earned) Oof in Noob Incremental! \(state.rebirthCount) rebirths and \(achievements)/\(totalAchievements) achievements unlocked."
    }
}
