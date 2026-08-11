import SwiftUI

/// The dedicated Game Passes shop, opened via ContentView's new ticket icon. Moved (not
/// duplicated) out of MoreSheet's old "Support the Game" section — same IAPProduct catalog,
/// same IAPManager/IAPSystem wiring already set up in ContentView.onAppear, just given its
/// own first-class screen with Roblox "Game Pass" framing instead of being buried in
/// Settings.
struct GamePassesSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Game Passes").font(.title2.weight(.bold)).foregroundStyle(.white)
                        Text("Permanent perks and currency packs, purchased once.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))

                        ForEach(IAPProduct.allCases) { product in
                            passRow(product)
                        }

                        Button("Restore Purchases") {
                            Task {
                                await iapManager.restorePurchases()
                                restoreMessage = "Restore complete."
                            }
                        }
                        .buttonStyle(PressableButtonStyle())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .accessibilityHint("Reapplies any purchases already made with this Apple ID")

                        if let restoreMessage {
                            Text(restoreMessage)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func passRow(_ product: IAPProduct) -> some View {
        let isOwned = product.kind == .nonConsumable && viewModel.isProductOwned(product)
        let storeProduct = iapManager.products[product]
        let isPurchasing = iapManager.purchasing == product

        return GlowCard(borderColor: .green) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(product.displayDescription)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                if isOwned {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Owned")
                } else {
                    Button {
                        Task { await iapManager.purchase(product) }
                    } label: {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(storeProduct?.displayPrice ?? "\u{2014}")
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(
                        storeProduct != nil ? AnyShapeStyle(Theme.oofGradient) : AnyShapeStyle(Color.white.opacity(0.15)),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(.white)
                    .disabled(storeProduct == nil || isPurchasing)
                    .accessibilityLabel("Buy \(product.displayName)")
                    .accessibilityValue(storeProduct?.displayPrice ?? "Unavailable")
                }
            }
        }
    }
}
