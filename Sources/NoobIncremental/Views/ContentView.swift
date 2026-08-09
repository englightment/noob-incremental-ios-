import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let earnings = viewModel.lastOfflineEarnings {
                OfflineEarningsBanner(amount: earnings) {
                    viewModel.dismissOfflineEarningsBanner()
                }
            }

            PrestigeBar(
                prestigeCount: viewModel.prestigeCount,
                progressText: viewModel.prestigeProgressText,
                progressFraction: viewModel.prestigeProgressFraction
            )

            VStack(spacing: 2) {
                Text(viewModel.formattedCurrency)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.formattedCurrency)
                HStack(spacing: 6) {
                    Text("Oof")
                        .foregroundStyle(.secondary)
                    if !viewModel.formattedIncomePerSecond.isEmpty {
                        Text(viewModel.formattedIncomePerSecond)
                            .foregroundStyle(.green)
                    }
                }
                .font(.subheadline)
            }

            TabView {
                NoobsTab(generators: viewModel.visibleGenerators, onUpgrade: viewModel.buyGenerator)
                    .tabItem { Label("Noobs", systemImage: "face.smiling.fill") }

                UpgradesTab(upgrades: viewModel.visibleUpgrades, onBuy: viewModel.buyUpgrade, onBuyMax: viewModel.buyUpgradeMax)
                    .tabItem { Label("Upgrades", systemImage: "arrow.up.circle.fill") }
            }
        }
        .padding()
        .onAppear { viewModel.start() }
    }
}

private struct PrestigeBar: View {
    let prestigeCount: Int
    let progressText: String
    let progressFraction: Double

    var body: some View {
        VStack(spacing: 4) {
            Text("Progress for Prestige \(prestigeCount + 1)")
                .font(.caption.weight(.semibold))
            ProgressView(value: progressFraction)
                .tint(.purple)
            Text(progressText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct NoobsTab: View {
    let generators: [GeneratorRowViewData]
    let onUpgrade: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(generators) { generator in
                    GeneratorRowView(data: generator) { onUpgrade(generator.id) }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct GeneratorRowView: View {
    let data: GeneratorRowViewData
    let onUpgrade: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.name)
                    .font(.headline)
                Text("Level \(data.level)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(data.outputPerLevelText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onUpgrade) {
                VStack(spacing: 2) {
                    Text("Upgrade")
                        .font(.subheadline.weight(.semibold))
                    Text(data.costText)
                        .font(.caption)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(data.canAfford ? Color.accentColor : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            }
            .disabled(!data.canAfford)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct UpgradesTab: View {
    let upgrades: [UpgradeRowViewData]
    let onBuy: (String) -> Void
    let onBuyMax: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(upgrades) { upgrade in
                    UpgradeRowView(data: upgrade, onBuy: { onBuy(upgrade.id) }, onBuyMax: { onBuyMax(upgrade.id) })
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct UpgradeRowView: View {
    let data: UpgradeRowViewData
    let onBuy: () -> Void
    let onBuyMax: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.name)
                .font(.headline)
            Text("\(data.level)/\(data.maxLevel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(data.effectText)
                .font(.subheadline.weight(.medium))

            HStack {
                Text(data.costText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Buy", action: onBuy)
                    .buttonStyle(.borderedProminent)
                    .disabled(data.isMaxed || !data.canAfford)
                Button("Max", action: onBuyMax)
                    .buttonStyle(.bordered)
                    .disabled(data.isMaxed || !data.canAfford)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(data.isMaxed ? 0.6 : 1.0)
    }
}

private struct OfflineEarningsBanner: View {
    let amount: Decimal
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text("While you were away: +\(NumberFormatting.format(amount)) Oof")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Dismiss", action: onDismiss)
                .font(.caption)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView(viewModel: GameViewModel())
}
