import Foundation

/// The two rewarded-ad placements. Both can be active at once and stack multiplicatively.
enum AdBoostTier: CaseIterable, Hashable {
    case twoX
    case fourX

    var multiplier: Decimal {
        switch self {
        case .twoX: return 2
        case .fourX: return 4
        }
    }

    var displayName: String {
        switch self {
        case .twoX: return "2x Oof"
        case .fourX: return "4x Oof"
        }
    }

    /// Google's public TEST rewarded ad unit ID for both placements — swap for your own
    /// per-placement ad unit IDs after creating an AdMob account. See RewardedAdManager.swift.
    var adUnitID: String { "ca-app-pub-3940256099942544/1712485313" }
}
