import Foundation

/// Pure application of a completed purchase to GameState, and the resulting entitlement
/// bonuses. Kept separate from IAPManager (the StoreKit-touching class) so this logic is
/// unit-testable without StoreKit at all — same split as AdBoostSystem/RewardedAdManager.
enum IAPSystem {
    static let supporterOutputMultiplier: Decimal = 1.1

    static func isOwned(_ product: IAPProduct, state: GameState) -> Bool {
        state.purchasedProductIDs.contains(product.rawValue)
    }

    /// Applies a completed transaction. Non-consumables record ownership (idempotent, since
    /// StoreKit can replay the same transaction more than once via Transaction.updates).
    /// Consumables never touch purchasedProductIDs — they just grant their reward every time,
    /// matching how a consumable can be bought repeatedly.
    static func applyPurchase(_ product: IAPProduct, to state: GameState) -> GameState {
        var next = state
        switch product.kind {
        case .nonConsumable:
            next.purchasedProductIDs.insert(product.rawValue)
        case .consumable:
            next.runeShards += product.runeShardGrant
        }
        return next
    }

    static func outputMultiplier(state: GameState) -> Decimal {
        isOwned(.supporterPack, state: state) ? supporterOutputMultiplier : 1
    }
}
