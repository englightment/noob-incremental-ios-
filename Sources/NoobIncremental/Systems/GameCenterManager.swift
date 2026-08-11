import Foundation
import GameKit
import UIKit

/// Thin wrapper around GameKit for Game Center sign-in, achievement reporting, and one
/// leaderboard (lifetime Oof earned).
///
/// Unlike the AdMob/StoreKit integrations, this doesn't need a special test setup to try
/// locally — GKLocalPlayer.local.authenticateHandler works against any Apple ID signed into
/// the simulator/device, no App Store Connect configuration required for the sign-in flow
/// itself. Before a real release:
///   1. Enable Game Center for this app in App Store Connect
///   2. Create the achievements there with IDs matching AchievementCatalog's own ids (reused
///      directly as GKAchievement identifiers below) and a leaderboard with id
///      `lifetime_oof_earned`
/// I can't verify the sign-in sheet or leaderboard UI myself: it requires a real device or
/// simulator session signed into Game Center, neither of which this environment has. The
/// pure score-conversion logic (GameCenterSystem) is unit-tested; this class itself isn't —
/// same caveat as RewardedAdManager/IAPManager.
@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let lifetimeEarnedLeaderboardID = "lifetime_oof_earned"

    @Published private(set) var isAuthenticated = false

    func authenticate() {
        // authenticateHandler's closure isn't MainActor-isolated (it's a plain GameKit
        // completion handler that can fire from any thread), but it needs to touch this
        // @MainActor class's @Published state — hop over explicitly with Task { @MainActor
        // in ... } rather than relying on the closure itself being inferred as isolated.
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.rootViewController()?.present(viewController, animated: true)
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    /// Reuses the achievement's own catalog id as the Game Center identifier — see the class
    /// doc for the matching App Store Connect setup needed before release.
    func reportAchievementUnlocked(_ achievementID: String) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = 100
        achievement.showsCompletionBanner = true
        Task {
            try? await GKAchievement.report([achievement])
        }
    }

    func reportLifetimeEarned(_ lifetimeEarned: Decimal) {
        guard isAuthenticated else { return }
        let score = GameCenterSystem.leaderboardScore(lifetimeEarned: lifetimeEarned)
        Task {
            try? await GKLeaderboard.submitScore(
                score, context: 0, player: GKLocalPlayer.local,
                leaderboardIDs: [Self.lifetimeEarnedLeaderboardID]
            )
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
