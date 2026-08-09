import SwiftUI

private enum Theme {
    static let background = LinearGradient(
        colors: [Color(red: 0.05, green: 0.02, blue: 0.16), Color(red: 0.13, green: 0.05, blue: 0.26)],
        startPoint: .top, endPoint: .bottom
    )
    static let oofGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.88, blue: 0.25), Color(red: 1.0, green: 0.55, blue: 0.1)],
        startPoint: .top, endPoint: .bottom
    )
    static let rebirthGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.4, blue: 0.85), Color(red: 0.6, green: 0.3, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )
    static let cardBackground = Color(red: 0.1, green: 0.08, blue: 0.19)
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 10) {
                if let earnings = viewModel.lastOfflineEarnings {
                    OfflineEarningsBanner(amount: earnings) {
                        viewModel.dismissOfflineEarningsBanner()
                    }
                }

                ZStack {
                    CurrencyDisplay(
                        valueText: viewModel.formattedCurrency,
                        title: "Oof",
                        subtitleText: viewModel.formattedIncomePerSecond,
                        gradient: Theme.oofGradient
                    )
                    FloatingTextOverlay(items: viewModel.floatingTexts, gradient: Theme.oofGradient)
                }
                .frame(height: 100)

                TabView {
                    NoobsTab(generators: viewModel.visibleGenerators, onUpgrade: viewModel.buyGenerator)
                        .tabItem { Label("Noobs", systemImage: "face.smiling.fill") }

                    UpgradesTab(upgrades: viewModel.visibleUpgrades, onBuy: viewModel.buyUpgrade, onBuyMax: viewModel.buyUpgradeMax)
                        .tabItem { Label("Upgrades", systemImage: "arrow.up.circle.fill") }

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
                    .tabItem { Label("Rebirth", systemImage: "arrow.triangle.2.circlepath") }
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.start() }
    }
}

// MARK: - Currency display + VFX

private struct CurrencyDisplay: View {
    let valueText: String
    let title: String
    let subtitleText: String
    let gradient: LinearGradient
    @State private var glowing = false

    var body: some View {
        VStack(spacing: 2) {
            Text(valueText)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(gradient)
                .shadow(color: .white.opacity(glowing ? 0.55 : 0.15), radius: glowing ? 16 : 6)
                .contentTransition(.numericText())
                .animation(.snappy, value: valueText)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        glowing = true
                    }
                }
            HStack(spacing: 6) {
                Text(title)
                    .foregroundStyle(.white.opacity(0.6))
                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .foregroundStyle(.green)
                }
            }
            .font(.subheadline.weight(.bold))
        }
    }
}

private struct FloatingTextOverlay: View {
    let items: [FloatingText]
    let gradient: LinearGradient

    var body: some View {
        ZStack {
            ForEach(items) { item in
                FloatingTextItemView(item: item, gradient: gradient)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FloatingTextItemView: View {
    let item: FloatingText
    let gradient: LinearGradient
    @State private var risen = false

    var body: some View {
        Text(item.text)
            .font(.headline.weight(.bold))
            .foregroundStyle(gradient)
            .offset(x: item.xOffset, y: risen ? -70 : -10)
            .opacity(risen ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.1)) {
                    risen = true
                }
            }
    }
}

// MARK: - Card container

private struct GlowCard<Content: View>: View {
    let borderColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(borderColor.opacity(0.55), lineWidth: 1.5))
            .shadow(color: borderColor.opacity(0.3), radius: 8)
    }
}

// MARK: - Noobs tab

private struct NoobsTab: View {
    let generators: [GeneratorRowViewData]
    let onUpgrade: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(generators) { generator in
                    GeneratorRowView(data: generator) { onUpgrade(generator.id) }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct GeneratorRowView: View {
    let data: GeneratorRowViewData
    let onUpgrade: () -> Void

    var body: some View {
        GlowCard(borderColor: .yellow) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Level \(data.level)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(data.outputPerLevelText)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Button(action: onUpgrade) {
                    VStack(spacing: 2) {
                        Text("Upgrade")
                            .font(.subheadline.weight(.bold))
                        Text(data.costText)
                            .font(.caption)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        data.canAfford ? AnyShapeStyle(Theme.oofGradient) : AnyShapeStyle(Color.gray.opacity(0.3)),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(.black)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!data.canAfford)
            }
        }
    }
}

// MARK: - Upgrades tab (shared row style for both Oof and Rebirth shops)

private struct UpgradesTab: View {
    let upgrades: [UpgradeRowViewData]
    let onBuy: (String) -> Void
    let onBuyMax: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(upgrades) { upgrade in
                    UpgradeRowView(data: upgrade, borderColor: .cyan, onBuy: { onBuy(upgrade.id) }, onBuyMax: { onBuyMax(upgrade.id) })
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct UpgradeRowView: View {
    let data: UpgradeRowViewData
    let borderColor: Color
    let onBuy: () -> Void
    let onBuyMax: () -> Void

    var body: some View {
        GlowCard(borderColor: borderColor) {
            VStack(alignment: .leading, spacing: 6) {
                Text(data.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(data.level)/\(data.maxLevel)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(data.effectText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(borderColor)

                HStack {
                    Text(data.costText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Button("Buy", action: onBuy)
                        .buttonStyle(PressableButtonStyle())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.red.opacity(data.isMaxed || !data.canAfford ? 0.2 : 0.85), in: Capsule())
                        .foregroundStyle(.white)
                        .disabled(data.isMaxed || !data.canAfford)
                    Button("Max", action: onBuyMax)
                        .buttonStyle(PressableButtonStyle())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.purple.opacity(data.isMaxed || !data.canAfford ? 0.2 : 0.85), in: Capsule())
                        .foregroundStyle(.white)
                        .disabled(data.isMaxed || !data.canAfford)
                }
            }
        }
        .opacity(data.isMaxed ? 0.6 : 1.0)
    }
}

// MARK: - Rebirth tab

private struct RebirthTab: View {
    let rebirthCurrencyText: String
    let rebirthCount: Int
    let canRebirth: Bool
    let gainPreviewText: String
    let requirementText: String
    let progressFraction: Double
    let onRebirth: () -> Void
    let upgrades: [UpgradeRowViewData]
    let onBuy: (String) -> Void
    let onBuyMax: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(rebirthCurrencyText)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.rebirthGradient)
                    Text("Rebirth \(rebirthCount)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 4)

                GlowCard(borderColor: .pink) {
                    VStack(spacing: 10) {
                        Text("Rebirth resets Oof, Oof Upgrades, and Noobs \u{2014} but keeps Rebirth currency and Rebirth Upgrades.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))

                        ProgressView(value: progressFraction)
                            .tint(.pink)
                        Text(requirementText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))

                        Button(action: onRebirth) {
                            Text(canRebirth ? "Rebirth (\(gainPreviewText))" : "Locked")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    canRebirth ? AnyShapeStyle(Theme.rebirthGradient) : AnyShapeStyle(Color.gray.opacity(0.25)),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .disabled(!canRebirth)
                    }
                }

                Text("Rebirth Upgrades")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(upgrades) { upgrade in
                    UpgradeRowView(data: upgrade, borderColor: .pink, onBuy: { onBuy(upgrade.id) }, onBuyMax: { onBuyMax(upgrade.id) })
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Offline earnings banner

private struct OfflineEarningsBanner: View {
    let amount: Decimal
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text("While you were away: +\(NumberFormatting.format(amount)) Oof")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button("Dismiss", action: onDismiss)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView(viewModel: GameViewModel())
}
