import Foundation

/// Pure conversions between game state and Game Center's data shapes, kept separate from
/// GameCenterManager (the GameKit-touching class) so this logic is unit-testable without
/// GameKit at all — same split as IAPSystem/IAPManager.
enum GameCenterSystem {
    /// Game Center leaderboard scores are a plain Int64. Lifetime Oof is a Decimal that can
    /// grow far past that at extreme late-game — clamp rather than let the Decimal-to-Int
    /// conversion overflow or crash.
    static func leaderboardScore(lifetimeEarned: Decimal) -> Int {
        guard lifetimeEarned > 0 else { return 0 }
        let clamped = min(lifetimeEarned, Decimal(Int.max))
        // NSNumber's `intValue` bridges to Int32 (mirroring Objective-C's 32-bit `int`), which
        // would silently truncate well before Int.max — Int(truncating:) is the unambiguous
        // Foundation-provided conversion that actually targets Int's real width.
        return Int(truncating: NSDecimalNumber(decimal: clamped))
    }
}
