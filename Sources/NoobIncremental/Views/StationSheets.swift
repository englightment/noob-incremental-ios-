import SwiftUI

/// Thin NavigationStack + dismiss-button wrappers around the existing Rebirth/Upgrades/
/// Runes tab content (see ContentView.swift), reused unchanged as the popup shown when the
/// player visits each station in the overworld — same content, same GameViewModel wiring,
/// just reached by walking there instead of tapping a tab.
struct RebirthAltarSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                RebirthTab(
                    rebirthCurrencyText: viewModel.formattedRebirthCurrency,
                    rebirthCount: viewModel.rebirthCount,
                    canRebirth: viewModel.canRebirth,
                    gainPreviewText: viewModel.rebirthGainPreviewText,
                    requirementText: viewModel.rebirthRequirementText,
                    progressFraction: viewModel.rebirthProgressFraction,
                    onRebirth: viewModel.performRebirth,
                    upgrades: viewModel.visibleRebirthUpgrades,
                    onBuy: viewModel.buyRebirthUpgrade,
                    onBuyMax: viewModel.buyRebirthUpgradeMax
                )
                .padding()
            }
            .navigationTitle("Rebirth Altar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct UpgradeWorkshopSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                UpgradesTab(upgrades: viewModel.visibleUpgrades, onBuy: viewModel.buyUpgrade, onBuyMax: viewModel.buyUpgradeMax)
                    .padding()
            }
            .navigationTitle("Upgrade Workshop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Read-only view of Rune progress, opened from the Rune Shrine station. Runes no longer
/// have a manual buy shop — standing at the shrine (OverworldView's rune auto-collection
/// task) automatically spends Rune Shards leveling runes up over time. This resolves the
/// earlier open question about whether Runes should be a paid gacha roll or passive
/// collection: the user confirmed passive collection is correct. This sheet is just a
/// status check, not a shop.
struct RuneShrineSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                RuneStatusView(runeShardsText: viewModel.formattedRuneShards, runes: viewModel.runeRows)
                    .padding()
            }
            .navigationTitle("Rune Shrine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct RuneStatusView: View {
    let runeShardsText: String
    let runes: [UpgradeRowViewData]
    @ScaledMetric(relativeTo: .largeTitle) private var currencyFontSize: CGFloat = 40

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(runeShardsText)
                        .font(.system(size: currencyFontSize, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .foregroundStyle(Theme.runeGradient)
                    Text("Rune Shards")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 4)

                Text("Runes level up automatically while you stand at the shrine. Come back to check their progress.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))

                ForEach(runes) { rune in
                    runeRow(rune)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func runeRow(_ rune: UpgradeRowViewData) -> some View {
        GlowCard(borderColor: .mint) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(rune.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(rune.isMaxed ? "MAX" : "\(rune.level)/\(rune.maxLevel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(rune.effectText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.mint)
                if !rune.isMaxed {
                    Text("Next level: \(rune.costText)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .opacity(rune.isMaxed ? 0.7 : 1.0)
    }
}
