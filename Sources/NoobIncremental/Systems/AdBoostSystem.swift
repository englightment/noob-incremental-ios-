import Foundation

/// Pure state for the two rewarded-ad boosts — mirrors BoostSystem's shape but tracks two
/// independent, stackable, long-duration boosts instead of one short random one. The actual
/// ad loading/showing is impure and lives in RewardedAdManager; this just answers "is this
/// tier active right now" from state, so GameLoop stays pure and testable.
enum AdBoostSystem {

    static func isActive(_ tier: AdBoostTier, state: GameState, now: Date = Date()) -> Bool {
        guard let expiresAt = expiry(tier, state: state) else { return false }
        return now < expiresAt
    }

    static func remainingSeconds(_ tier: AdBoostTier, state: GameState, now: Date = Date()) -> TimeInterval {
        guard let expiresAt = expiry(tier, state: state), expiresAt > now else { return 0 }
        return expiresAt.timeIntervalSince(now)
    }

    /// Product of every currently-active tier's multiplier (1 if none are active).
    static func combinedMultiplier(state: GameState, now: Date = Date()) -> Decimal {
        AdBoostTier.allCases.reduce(Decimal(1)) { total, tier in
            isActive(tier, state: state, now: now) ? total * tier.multiplier : total
        }
    }

    static func activate(_ tier: AdBoostTier, state: GameState, duration: TimeInterval, now: Date = Date()) -> GameState {
        var next = state
        let expiresAt = now.addingTimeInterval(duration)
        switch tier {
        case .twoX: next.adBoost2xExpiresAt = expiresAt
        case .fourX: next.adBoost4xExpiresAt = expiresAt
        }
        return next
    }

    private static func expiry(_ tier: AdBoostTier, state: GameState) -> Date? {
        switch tier {
        case .twoX: return state.adBoost2xExpiresAt
        case .fourX: return state.adBoost4xExpiresAt
        }
    }
}
