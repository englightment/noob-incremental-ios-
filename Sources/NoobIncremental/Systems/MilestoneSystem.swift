import Foundation

/// Net-worth milestone tiers (powers of ten, starting at 100) drive a one-time confetti
/// celebration each time lifetime Oof crosses into a new tier.
enum MilestoneSystem {

    /// Tier 0 means no milestone reached yet; tier 1 = 100, tier 2 = 1,000, tier 3 = 10,000, ...
    static func tier(for lifetimeEarned: Decimal) -> Int {
        guard lifetimeEarned >= 100 else { return 0 }
        let value = NSDecimalNumber(decimal: lifetimeEarned).doubleValue
        return max(0, Int(floor(log10(value))) - 1)
    }

    static func threshold(forTier tier: Int) -> Decimal {
        guard tier > 0 else { return 100 }
        return Decimal(pow(10.0, Double(tier + 1)))
    }

    static func hasNewMilestone(state: GameState) -> Bool {
        tier(for: state.lifetimeEarned) > state.highestMilestoneCelebrated
    }

    /// Records the current tier as celebrated. Returns state unchanged if there's no new milestone.
    static func celebrate(state: GameState) -> GameState {
        guard hasNewMilestone(state: state) else { return state }
        var next = state
        next.highestMilestoneCelebrated = tier(for: state.lifetimeEarned)
        return next
    }
}
