import Foundation
import StoreKit

/// Thin wrapper around StoreKit 2 for the game's IAP catalog (see IAPProduct).
///
/// For testing without an App Store Connect account, this project ships a local StoreKit
/// configuration file (Configuration.storekit, at the repo root) with the same product IDs
/// as IAPProduct — the same "test now, swap for real store config before release" pattern
/// already used for AdMob (see RewardedAdManager). Since this project is built without
/// Xcode (no Mac available), the config file can't be wired into the scheme from here —
/// whoever opens this in Xcode should select it once via Product > Scheme > Edit Scheme >
/// Run/Test > Options > StoreKit Configuration to enable purchases in the simulator. Before
/// a real release:
///   1. Create matching in-app purchase products in App Store Connect (same product IDs
///      as IAPProduct's raw values)
///   2. Switch the scheme's StoreKit Configuration back to "None" so real store data is used
/// I can't verify the purchase sheet or receipt flow myself: it requires Xcode's StoreKit
/// Testing environment or a real device, neither of which this environment has. The pure
/// entitlement logic (IAPSystem) is unit-tested; this class itself isn't — same caveat as
/// RewardedAdManager.
@MainActor
final class IAPManager: NSObject, ObservableObject {
    @Published private(set) var products: [IAPProduct: Product] = [:]
    @Published private(set) var purchasing: IAPProduct?

    /// Called once a transaction for `product` has verified successfully. The caller is
    /// responsible for applying IAPSystem.applyPurchase to the game's state.
    var onPurchaseCompleted: ((IAPProduct) -> Void)?

    private var updatesTask: Task<Void, Never>?

    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await loadProducts() }
    }

    func loadProducts() async {
        guard let storeProducts = try? await Product.products(for: IAPProduct.allCases.map(\.rawValue)) else { return }
        var next: [IAPProduct: Product] = [:]
        for storeProduct in storeProducts {
            if let product = IAPProduct(rawValue: storeProduct.id) {
                next[product] = storeProduct
            }
        }
        products = next
    }

    /// Reconciles local entitlements against StoreKit's own record of what this Apple ID has
    /// bought — the recovery path for #12: local save data can be wiped (Sideloadly re-signing,
    /// a reinstall, a restored backup that predates a purchase) while the App Store still knows
    /// the transaction happened. Safe to call anytime; re-applying an already-owned
    /// non-consumable is a no-op (IAPSystem.applyPurchase is idempotent for those). Consumables
    /// don't appear in currentEntitlements once finished, so this can't double-grant them.
    func restorePurchases() async {
        try? await AppStore.sync()
        for await entitlement in Transaction.currentEntitlements {
            await handle(entitlement)
        }
    }

    func purchase(_ product: IAPProduct) async {
        guard let storeProduct = products[product], purchasing == nil else { return }
        purchasing = product
        defer { purchasing = nil }
        guard let result = try? await storeProduct.purchase() else { return }
        if case .success(let verification) = result {
            await handle(verification)
        }
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        if let product = IAPProduct(rawValue: transaction.productID) {
            onPurchaseCompleted?(product)
        }
        await transaction.finish()
    }

    deinit {
        updatesTask?.cancel()
    }
}
