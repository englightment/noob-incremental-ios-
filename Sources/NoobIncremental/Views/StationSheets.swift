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

/// Reuses the existing, already-built Rune-leveling shop (RuneStore/RunesTab) as the Rune
/// Shrine's content for now. The user separately shared a reference screenshot showing Runes
/// working as a paid gacha roll with weighted rarity odds, which is a different mechanic —
/// but without exact odds/reward data to build against, and since this is a real, working,
/// already-tested feature versus an unverified new system, shipping this now (reachable
/// spatially, satisfying "go to a rune") is the safer call. The gacha-roll mechanic can
/// replace or extend this once that's nailed down.
struct RuneShrineSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                RunesTab(
                    runeShardsText: viewModel.formattedRuneShards,
                    runes: viewModel.runeRows,
                    onBuy: viewModel.buyRune,
                    onBuyMax: viewModel.buyRuneMax
                )
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
