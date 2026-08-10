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

private enum BuyQuantity: String, CaseIterable, Identifiable {
    case one = "x1", ten = "x10", hundred = "x100", max = "Max"
    var id: String { rawValue }
}

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showMore = false
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 10) {
                HStack {
                    NoobFaceView(size: 30)
                    Text("Noob Incremental")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button(action: { showMore = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                if viewModel.canClaimDailyReward {
                    DailyRewardBanner(
                        streakDay: viewModel.pendingStreakDay,
                        rewardText: viewModel.pendingDailyRewardText,
                        onClaim: viewModel.claimDailyReward
                    )
                }

                if let earnings = viewModel.lastOfflineEarnings {
                    OfflineEarningsBanner(amount: earnings) {
                        viewModel.dismissOfflineEarningsBanner()
                    }
                }

                if viewModel.isBoostActive {
                    BoostBanner(multiplierText: viewModel.boostMultiplierText, remainingText: viewModel.boostRemainingSecondsText)
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
                    NoobsTab(
                        generators: viewModel.generatorRows,
                        onUpgrade: viewModel.buyGenerator,
                        onUpgradeMax: viewModel.buyGeneratorMax
                    )
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

            if let achievement = viewModel.achievementToast {
                VStack {
                    AchievementToastView(achievement: achievement)
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.achievementToast?.id)
            }

            if viewModel.showMilestoneCelebration {
                ConfettiView(pieces: confettiPieces)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.start() }
        .onChange(of: viewModel.showMilestoneCelebration) { _, isShowing in
            if isShowing {
                confettiPieces = ConfettiView.randomBurst()
            }
        }
        .sheet(isPresented: $showMore) {
            MoreSheet(viewModel: viewModel)
        }
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

// MARK: - Boost banner

private struct BoostBanner: View {
    let multiplierText: String
    let remainingText: String
    @State private var pulse = false

    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.yellow)
            Text("Lucky Surge! \(multiplierText) Oof \u{2014} \(remainingText) left")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(10)
        .background(Theme.rebirthGradient.opacity(pulse ? 0.9 : 0.6), in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Daily reward banner

private struct DailyRewardBanner: View {
    let streakDay: Int
    let rewardText: String
    let onClaim: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Day \(streakDay) Streak")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Claim \(rewardText) \u{2014} don't lose your streak!")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button("Claim", action: onClaim)
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.oofGradient, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.black)
                .font(.subheadline.weight(.bold))
        }
        .padding(10)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.6), lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.3), radius: 8)
    }
}

// MARK: - Achievement toast

private struct AchievementToastView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Theme.oofGradient)
            VStack(alignment: .leading, spacing: 1) {
                Text("Achievement Unlocked")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(achievement.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.yellow.opacity(0.6), lineWidth: 1.5))
        .shadow(color: .yellow.opacity(0.3), radius: 10)
        .padding(.horizontal)
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
    let onUpgrade: (String, Int) -> Void
    let onUpgradeMax: (String) -> Void
    @State private var quantity: BuyQuantity = .one

    var body: some View {
        VStack(spacing: 8) {
            Picker("Quantity", selection: $quantity) {
                ForEach(BuyQuantity.allCases) { q in
                    Text(q.rawValue).tag(q)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(generators) { generator in
                        GeneratorRowView(data: generator, quantity: quantity) {
                            switch quantity {
                            case .one: onUpgrade(generator.id, 1)
                            case .ten: onUpgrade(generator.id, 10)
                            case .hundred: onUpgrade(generator.id, 100)
                            case .max: onUpgradeMax(generator.id)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct GeneratorRowView: View {
    let data: GeneratorRowViewData
    let quantity: BuyQuantity
    let onUpgrade: () -> Void

    private var costText: String {
        switch quantity {
        case .one: return data.costX1
        case .ten: return data.costX10
        case .hundred: return data.costX100
        case .max: return data.maxAffordableCount > 0 ? "x\(data.maxAffordableCount)" : "\u{2014}"
        }
    }

    private var canAfford: Bool {
        switch quantity {
        case .one: return data.canAffordX1
        case .ten: return data.canAffordX10
        case .hundred: return data.canAffordX100
        case .max: return data.maxAffordableCount > 0
        }
    }

    var body: some View {
        GlowCard(borderColor: .yellow) {
            HStack {
                NoobFaceView(size: 40)
                    .saturation(data.isLocked ? 0 : 1)
                    .opacity(data.isLocked ? 0.35 : 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.name)
                        .font(.headline)
                        .foregroundStyle(data.isLocked ? .white.opacity(0.4) : .white)
                    if data.isLocked {
                        Text(data.unlockText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text("Level \(data.level)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(data.outputPerLevelText)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                if data.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.trailing, 6)
                } else {
                    Button(action: onUpgrade) {
                        VStack(spacing: 2) {
                            Text(quantity == .max ? "Buy Max" : "Upgrade")
                                .font(.subheadline.weight(.bold))
                            Text(costText)
                                .font(.caption)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            canAfford ? AnyShapeStyle(Theme.oofGradient) : AnyShapeStyle(Color.gray.opacity(0.3)),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .foregroundStyle(.black)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(!canAfford)
                }
            }
        }
        .opacity(data.isLocked ? 0.55 : 1.0)
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

// MARK: - More sheet (stats, achievements, codes, settings)

private struct MoreSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var codeText = ""
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        statsSection
                        codesSection
                        achievementsSection
                        settingsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statsSection: some View {
        GlowCard(borderColor: .cyan) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Stats").font(.headline).foregroundStyle(.white)
                statRow("Lifetime Oof", viewModel.lifetimeEarnedText)
                statRow("Total Noob Levels", "\(viewModel.totalNoobLevels)")
                statRow("Rebirths", "\(viewModel.rebirthCount)")
                statRow("Login Streak", "\(viewModel.currentStreak) days")
                statRow("Achievements", "\(viewModel.unlockedAchievementCount)/\(viewModel.totalAchievementCount)")
                statRow("Time Played", viewModel.totalPlayTimeText)
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value).font(.caption.weight(.bold)).foregroundStyle(.white)
        }
    }

    private var codesSection: some View {
        GlowCard(borderColor: .purple) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Redeem Code").font(.headline).foregroundStyle(.white)
                HStack {
                    TextField("Enter code", text: $codeText)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                    Button("Redeem") {
                        viewModel.redeemCode(codeText)
                        codeText = ""
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.rebirthGradient, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                if let message = viewModel.redeemMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private var achievementsSection: some View {
        GlowCard(borderColor: .yellow) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Achievements (\(viewModel.unlockedAchievementCount)/\(viewModel.totalAchievementCount))")
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(viewModel.achievementRows) { row in
                    HStack(spacing: 8) {
                        Image(systemName: row.isUnlocked ? "trophy.fill" : "lock.fill")
                            .foregroundStyle(row.isUnlocked ? AnyShapeStyle(Theme.oofGradient) : AnyShapeStyle(Color.white.opacity(0.3)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.name)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(row.isUnlocked ? .white : .white.opacity(0.4))
                            Text(row.description)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        GlowCard(borderColor: .gray) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Settings").font(.headline).foregroundStyle(.white)

                Toggle(isOn: Binding(get: { viewModel.soundEnabled }, set: { _ in viewModel.toggleSound() })) {
                    Text("Sound").foregroundStyle(.white)
                }
                .tint(.pink)

                Toggle(isOn: Binding(get: { viewModel.hapticsEnabled }, set: { _ in viewModel.toggleHaptics() })) {
                    Text("Haptics").foregroundStyle(.white)
                }
                .tint(.pink)

                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Text("Reset Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.red)
                }
                .confirmationDialog("Reset all progress? This can't be undone.", isPresented: $showResetConfirm, titleVisibility: .visible) {
                    Button("Reset Everything", role: .destructive) { viewModel.resetSave() }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: GameViewModel())
}
