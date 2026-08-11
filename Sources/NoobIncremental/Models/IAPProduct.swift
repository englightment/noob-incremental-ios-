import Foundation

/// Catalog of purchasable products. Raw values are StoreKit product identifiers.
///
/// Backed by a local StoreKit configuration file (Configuration.storekit, repo root) for
/// testing without an App Store Connect account — the "test now, swap for real config
/// later" pattern already used for AdMob, see RewardedAdManager and IAPManager. Before a
/// real App Store release, create matching in-app purchase products in App Store Connect
/// with these same IDs.
enum IAPProduct: String, CaseIterable, Identifiable, Hashable {
    case supporterPack = "com.taragod.noobincremental.supporterpack"
    case runeShardPackSmall = "com.taragod.noobincremental.runeshardpack.small"
    case runeShardPackLarge = "com.taragod.noobincremental.runeshardpack.large"

    var id: String { rawValue }

    enum Kind: Equatable { case consumable, nonConsumable }

    var kind: Kind {
        switch self {
        case .supporterPack: return .nonConsumable
        case .runeShardPackSmall, .runeShardPackLarge: return .consumable
        }
    }

    var displayName: String {
        switch self {
        case .supporterPack: return "Supporter Pack"
        case .runeShardPackSmall: return "Pouch of Rune Shards"
        case .runeShardPackLarge: return "Chest of Rune Shards"
        }
    }

    var displayDescription: String {
        switch self {
        case .supporterPack: return "A thank-you badge and a permanent +10% Oof boost, forever."
        case .runeShardPackSmall: return "+25 Rune Shards, added instantly."
        case .runeShardPackLarge: return "+120 Rune Shards, added instantly."
        }
    }

    /// Rune Shards granted immediately on purchase. Only meaningful for consumable packs —
    /// the supporter pack's effect is a persistent multiplier via IAPSystem.outputMultiplier
    /// instead, tracked through ownership rather than a one-time grant.
    var runeShardGrant: Decimal {
        switch self {
        case .runeShardPackSmall: return 25
        case .runeShardPackLarge: return 120
        case .supporterPack: return 0
        }
    }
}
