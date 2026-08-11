import SwiftUI
import UIKit

private enum Theme {
    static let oofGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.88, blue: 0.25), Color(red: 1.0, green: 0.55, blue: 0.1)],
        startPoint: .top, endPoint: .bottom
    )
    static let rebirthGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.4, blue: 0.85), Color(red: 0.6, green: 0.3, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )
    static let runeGradient = LinearGradient(
        colors: [Color(red: 0.3, green: 0.95, blue: 0.8), Color(red: 0.15, green: 0.6, blue: 0.55)],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Ambient background

/// Slow-drifting blurred color blobs over a deep gradient base, instead of a flat two-stop
/// fill — gives the whole app a sense of depth for the glass cards to sit on top of.
private struct AppBackground: View {
    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.11),
                    Color(red: 0.10, green: 0.04, blue: 0.22),
                    Color(red: 0.05, green: 0.02, blue: 0.14)
                ],
                startPoint: .top, endPoint: .bottom
            )

            blob(color: .purple, size: 420, x: drift ? -130 : -170, y: drift ? -320 : -260)
            blob(color: .pink, size: 380, x: drift ? 160 : 190, y: drift ? 440 : 400)
            blob(color: .cyan, size: 320, x: drift ? 150 : 110, y: drift ? -60 : -20)
        }
        .ignoresSafeArea()
        .onAppear {
            // Reduce Motion: skip the continuous drift entirely rather than just shortening
            // it — this is exactly the kind of ambient, purely-decorative looping motion the
            // setting exists to suppress.
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .offset(x: x, y: y)
            .blur(radius: 50)
    }
}

// MARK: - Glass panel (shared card/banner styling)

private struct GlassPanel: ViewModifier {
    var tint: Color
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.22), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(0.75), tint.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: tint.opacity(0.25), radius: 14, y: 6)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

private extension View {
    func glassPanel(tint: Color, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassPanel(tint: tint, cornerRadius: cornerRadius))
    }
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

// MARK: - Custom tab bar

private enum AppTab: Hashable, CaseIterable, Identifiable {
    case noobs, upgrades, rebirth, runes
    var id: Self { self }

    var title: String {
        switch self {
        case .noobs: return "Noobs"
        case .upgrades: return "Upgrades"
        case .rebirth: return "Rebirth"
        case .runes: return "Runes"
        }
    }

    var icon: String {
        switch self {
        case .noobs: return "face.smiling.fill"
        case .upgrades: return "arrow.up.circle.fill"
        case .rebirth: return "arrow.triangle.2.circlepath"
        case .runes: return "seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .noobs: return .yellow
        case .upgrades: return .cyan
        case .rebirth: return .pink
        case .runes: return .mint
        }
    }
}

private struct PillTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.35, dampingFraction: 0.82)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .bold))
                        Text(tab.title)
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(selection == tab ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tab.tint.opacity(0.85))
                                .matchedGeometryEffect(id: "selectedTab", in: namespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel
    @StateObject private var adManager = RewardedAdManager()
    @State private var showMore = false
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var selectedTab: AppTab = .noobs
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 10) {
                HStack {
                    NoobFaceView(size: 30)
                    Text("Noob Incremental")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button(action: { showMore = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(PressableButtonStyle())
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassPanel(tint: .yellow, cornerRadius: 22)
                    FloatingTextOverlay(items: viewModel.floatingTexts, gradient: Theme.oofGradient)
                }
                .frame(height: 108)

                PillTabBar(selection: $selectedTab)

                Group {
                    switch selectedTab {
                    case .noobs:
                        NoobsTab(
                            worlds: viewModel.worldRows,
                            generators: viewModel.generatorRows,
                            onUpgrade: viewModel.buyGenerator,
                            onUpgradeMax: viewModel.buyGeneratorMax
                        )
                    case .upgrades:
                        UpgradesTab(upgrades: viewModel.visibleUpgrades, onBuy: viewModel.buyUpgrade, onBuyMax: viewModel.buyUpgradeMax)
                    case .rebirth:
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
                    case .runes:
                        RunesTab(
                            runeShardsText: viewModel.formattedRuneShards,
                            runes: viewModel.runeRows,
                            onBuy: viewModel.buyRune,
                            onBuyMax: viewModel.buyRuneMax
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()

            if let achievement = viewModel.achievementToast {
                VStack {
                    AchievementToastView(achievement: achievement)
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .animation(reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.achievementToast?.id)
            }

            // Confetti is purely decorative celebration motion — skip it entirely under
            // Reduce Motion rather than just toning it down; the achievement/milestone
            // itself is still granted either way.
            if viewModel.showMilestoneCelebration && !reduceMotion {
                ConfettiView(pieces: confettiPieces)
            }

            if viewModel.showOnboarding {
                OnboardingOverlay {
                    viewModel.dismissOnboarding()
                }
                .transition(.opacity)
                .animation(.easeOut(duration: 0.3), value: viewModel.showOnboarding)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.start()
            adManager.start()
        }
        .onChange(of: viewModel.showMilestoneCelebration) { _, isShowing in
            if isShowing {
                confettiPieces = ConfettiView.randomBurst()
            }
        }
        .sheet(isPresented: $showMore) {
            MoreSheet(viewModel: viewModel, adManager: adManager)
        }
    }
}

// MARK: - First-launch onboarding

private struct OnboardingOverlay: View {
    let onDismiss: () -> Void

    private let steps: [(icon: String, text: String)] = [
        ("face.smiling.fill", "Noobs work for you \u{2014} buy them and watch Oof grow, even while you're away."),
        ("arrow.up.circle.fill", "Spend Oof on more Noobs and Upgrades to grow faster."),
        ("arrow.triangle.2.circlepath", "Once you've saved enough, Rebirth for a permanent currency that unlocks powerful upgrades.")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                NoobFaceView(size: 56)
                Text("Welcome to Noob Incremental!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: step.icon)
                                .font(.title3)
                                .foregroundStyle(Theme.oofGradient)
                                .frame(width: 26)
                            Text(step.text)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .padding(.top, 4)

                Button("Let's Go!", action: onDismiss)
                    .buttonStyle(PressableButtonStyle())
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.oofGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.black)
                    .padding(.top, 6)
            }
            .padding(24)
            .glassPanel(tint: .yellow, cornerRadius: 24)
            .padding(.horizontal, 28)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 2) {
            Text(valueText)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(gradient)
                .shadow(color: .white.opacity(glowing ? 0.55 : 0.15), radius: glowing ? 16 : 6)
                .contentTransition(.numericText())
                .animation(.snappy, value: valueText)
                .onAppear {
                    guard !reduceMotion else { return }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .background(Theme.rebirthGradient.opacity(pulse ? 0.9 : 0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            guard !reduceMotion else { return }
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
                .background(Theme.oofGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.black)
                .font(.subheadline.weight(.bold))
        }
        .padding(10)
        .glassPanel(tint: .orange, cornerRadius: 16)
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
        .glassPanel(tint: .yellow, cornerRadius: 16)
        .padding(.horizontal)
    }
}

// MARK: - Card container

private struct GlowCard<Content: View>: View {
    let borderColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .glassPanel(tint: borderColor, cornerRadius: 18)
    }
}

// MARK: - Noobs tab

private enum WorldThemeKind {
    case jungle, space, desert

    static func kind(for zoneID: String) -> WorldThemeKind {
        switch zoneID {
        case WorldCatalog.zone1ID: return .jungle
        case WorldCatalog.zone2ID: return .space
        case WorldCatalog.zone3ID: return .desert
        default: return .jungle
        }
    }

    var tint: Color {
        switch self {
        case .jungle: return .green
        case .space: return .purple
        case .desert: return .orange
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .jungle:
            return [Color(red: 0.02, green: 0.12, blue: 0.06), Color(red: 0.05, green: 0.22, blue: 0.10), Color(red: 0.02, green: 0.10, blue: 0.05)]
        case .space:
            return [Color(red: 0.02, green: 0.02, blue: 0.10), Color(red: 0.10, green: 0.04, blue: 0.24), Color(red: 0.02, green: 0.02, blue: 0.12)]
        case .desert:
            return [Color(red: 0.18, green: 0.07, blue: 0.02), Color(red: 0.35, green: 0.16, blue: 0.04), Color(red: 0.12, green: 0.04, blue: 0.06)]
        }
    }
}

private func worldTint(for zoneID: String) -> Color {
    WorldThemeKind.kind(for: zoneID).tint
}

private struct WorldBackdrop: View {
    let zoneID: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var kind: WorldThemeKind { WorldThemeKind.kind(for: zoneID) }

    var body: some View {
        ZStack {
            LinearGradient(colors: kind.gradientColors, startPoint: .top, endPoint: .bottom)
            motifs
        }
        .allowsHitTesting(false)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: zoneID)
    }

    @ViewBuilder
    private var motifs: some View {
        switch kind {
        case .jungle: JungleMotifs()
        case .space: SpaceMotifs()
        case .desert: DesertMotifs()
        }
    }
}

private struct JungleMotifs: View {
    private let leafOffsets: [(CGFloat, CGFloat, Double, Double)] = [
        (-140, -220, 24, 0.16), (150, -260, -18, 0.14), (-170, 180, 12, 0.12),
        (160, 240, -30, 0.15), (0, -300, 8, 0.10), (-100, 60, -22, 0.11)
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.yellow.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 320, height: 320)
                .offset(x: -110, y: -280)
                .blur(radius: 40)
            Circle()
                .fill(RadialGradient(colors: [Color.green.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 360, height: 360)
                .offset(x: 130, y: 260)
                .blur(radius: 50)
            ForEach(Array(leafOffsets.enumerated()), id: \.offset) { _, leaf in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Color.green.opacity(leaf.3))
                    .rotationEffect(.degrees(leaf.2))
                    .offset(x: leaf.0, y: leaf.1)
            }
        }
    }
}

private struct SpaceMotifs: View {
    private let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
        (-160, -320, 2), (140, -280, 3), (-100, -180, 1.5), (170, -120, 2),
        (-180, 40, 2.5), (120, 100, 1.5), (-60, 220, 2), (60, -350, 1.5),
        (200, 200, 2), (-200, 300, 1.5), (10, 300, 2), (-40, -260, 1.5)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(starPositions.enumerated()), id: \.offset) { _, star in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: star.2, height: star.2)
                    .offset(x: star.0, y: star.1)
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.55), Color.blue.opacity(0.25), .clear],
                        center: .center, startRadius: 0, endRadius: 110
                    )
                )
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -260)
                .blur(radius: 6)
            Ellipse()
                .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 3)
                .frame(width: 260, height: 70)
                .rotationEffect(.degrees(-20))
                .offset(x: 120, y: -260)
            Circle()
                .fill(RadialGradient(colors: [Color.pink.opacity(0.25), .clear], center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 380, height: 380)
                .offset(x: -140, y: 300)
                .blur(radius: 50)
        }
    }
}

private struct DesertMotifs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.yellow.opacity(0.45), Color.orange.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 260, height: 260)
                .offset(x: 0, y: -300)
                .blur(radius: 10)
            duneShape
                .fill(Color.black.opacity(0.28))
                .offset(y: 210)
            duneShape
                .fill(Color.black.opacity(0.4))
                .offset(y: 260)
                .scaleEffect(x: 1.15, y: 0.8, anchor: .bottom)
        }
    }

    private var duneShape: some Shape {
        Path { path in
            path.move(to: CGPoint(x: -220, y: 60))
            path.addCurve(to: CGPoint(x: 220, y: 60), control1: CGPoint(x: -80, y: -60), control2: CGPoint(x: 80, y: 100))
            path.addLine(to: CGPoint(x: 220, y: 200))
            path.addLine(to: CGPoint(x: -220, y: 200))
            path.closeSubpath()
        }
    }
}

private struct NoobsTab: View {
    let worlds: [WorldRowViewData]
    let generators: [GeneratorRowViewData]
    let onUpgrade: (String, Int) -> Void
    let onUpgradeMax: (String) -> Void
    @State private var quantity: BuyQuantity = .one
    @State private var selectedZoneID: String = WorldCatalog.zone1ID

    private var selectedWorld: WorldRowViewData? {
        worlds.first { $0.id == selectedZoneID }
    }

    private var rowsForSelectedZone: [GeneratorRowViewData] {
        generators.filter { $0.zoneID == selectedZoneID }
    }

    var body: some View {
        ZStack {
            WorldBackdrop(zoneID: selectedZoneID)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 8) {
                Picker("Quantity", selection: $quantity) {
                    ForEach(BuyQuantity.allCases) { q in
                        Text(q.rawValue).tag(q)
                    }
                }
                .pickerStyle(.segmented)

                if let world = selectedWorld, !world.isUnlocked {
                    GlowCard(borderColor: .gray) {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.4))
                            Text(world.name)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(world.lockedDescription)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(rowsForSelectedZone) { generator in
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

                if worlds.count > 1 {
                    WorldSelector(worlds: worlds, selectedZoneID: $selectedZoneID)
                }
            }
            .padding(10)
        }
    }
}

private struct WorldSelector: View {
    let worlds: [WorldRowViewData]
    @Binding var selectedZoneID: String
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(worlds) { world in
                let tint = worldTint(for: world.id)
                let isSelected = world.id == selectedZoneID

                Button {
                    guard world.isUnlocked else { return }
                    withAnimation(reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedZoneID = world.id
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: world.isUnlocked ? world.icon : "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text(world.name)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(world.isUnlocked ? 0.65 : 0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [tint, tint.opacity(0.6)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .matchedGeometryEffect(id: "selectedWorld", in: namespace)
                                .shadow(color: tint.opacity(0.5), radius: 8, y: 3)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(tint.opacity(isSelected ? 0 : (world.isUnlocked ? 0.5 : 0.15)), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .opacity(world.isUnlocked ? 1 : 0.6)
            }
        }
        .padding(6)
        .glassPanel(tint: .white, cornerRadius: 20)
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
                        if let bonus = data.milestoneBonusText {
                            Text(bonus)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.cyan)
                        } else if let next = data.nextMilestoneText {
                            Text("Milestone: \(next)")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.35))
                        }
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
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(borderColor.opacity(data.isMaxed || !data.canAfford ? 0.18 : 0.85), in: Capsule())
                        .foregroundStyle(.white)
                        .disabled(data.isMaxed || !data.canAfford)
                    Button("Max", action: onBuyMax)
                        .buttonStyle(PressableButtonStyle())
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(borderColor.opacity(data.isMaxed || !data.canAfford ? 0.1 : 0.5), in: Capsule())
                        .overlay(Capsule().strokeBorder(borderColor.opacity(data.isMaxed || !data.canAfford ? 0.15 : 0.7), lineWidth: 1))
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
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
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

// MARK: - Runes tab

private struct RunesTab: View {
    let runeShardsText: String
    let runes: [UpgradeRowViewData]
    let onBuy: (String) -> Void
    let onBuyMax: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(runeShardsText)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.runeGradient)
                    Text("Rune Shards")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 4)

                Text("Earned from Lucky Surges and net-worth milestones \u{2014} spend them on permanent Runes.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))

                ForEach(runes) { rune in
                    UpgradeRowView(data: rune, borderColor: .mint, onBuy: { onBuy(rune.id) }, onBuyMax: { onBuyMax(rune.id) })
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
        .glassPanel(tint: .white, cornerRadius: 16)
    }
}

// MARK: - More sheet (stats, achievements, codes, settings)

private struct MoreSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var adManager: RewardedAdManager
    @Environment(\.dismiss) private var dismiss
    @State private var codeText = ""
    @State private var showResetConfirm = false
    @State private var importCodeText = ""
    @State private var backupMessage: String?
    @State private var showImportConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        statsSection
                        minionsSection
                        adBoostsSection
                        codesSection
                        backupSection
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
                statRow("Total Earned", viewModel.lifetimeEarnedText)
                statRow("Total Noob Levels", "\(viewModel.totalNoobLevels)")
                statRow("Rebirths", "\(viewModel.rebirthCount)")
                statRow("Rune Shards", viewModel.formattedRuneShards)
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

    private var minionsSection: some View {
        GlowCard(borderColor: .mint) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minions").font(.headline).foregroundStyle(.white)
                    Spacer()
                    Text("\(viewModel.equippedMinionCount)/\(viewModel.maxEquippedMinions) equipped")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                ForEach(viewModel.minionRows) { minion in
                    minionRow(minion)
                }
            }
        }
    }

    private func minionRow(_ minion: MinionRowViewData) -> some View {
        let atCap = !minion.isEquipped && viewModel.equippedMinionCount >= viewModel.maxEquippedMinions

        return HStack(spacing: 10) {
            Image(systemName: minion.icon)
                .font(.title3)
                .frame(width: 30)
                .foregroundStyle(minion.isOwned ? AnyShapeStyle(Theme.runeGradient) : AnyShapeStyle(Color.white.opacity(0.25)))

            VStack(alignment: .leading, spacing: 1) {
                Text(minion.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(minion.isOwned ? .white : .white.opacity(0.4))
                Text(minion.isOwned ? minion.bonusText : "Locked \u{2014} \(minion.unlockHint)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            if minion.isOwned {
                Button(minion.isEquipped ? "Unequip" : "Equip") {
                    viewModel.toggleMinionEquip(id: minion.id)
                }
                .buttonStyle(PressableButtonStyle())
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    minion.isEquipped ? Color.mint.opacity(0.85) : Color.mint.opacity(atCap ? 0.1 : 0.5),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(Color.mint.opacity(minion.isEquipped ? 0 : (atCap ? 0.15 : 0.7)), lineWidth: 1))
                .foregroundStyle(.white)
                .disabled(atCap)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private var adBoostsSection: some View {
        GlowCard(borderColor: .orange) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ad Boosts").font(.headline).foregroundStyle(.white)
                ForEach(AdBoostTier.allCases, id: \.self) { tier in
                    adBoostRow(tier)
                }
            }
        }
    }

    private func adBoostRow(_ tier: AdBoostTier) -> some View {
        let isActive = viewModel.isAdBoostActive(tier)
        let isReady = adManager.isReady[tier] == true

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.displayName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                if isActive {
                    Text("Active — \(viewModel.adBoostRemainingText(tier)) left")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text("Watch an ad for 8 hours of \(tier.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
            if !isActive {
                Button {
                    adManager.show(tier) {
                        viewModel.grantAdBoost(tier)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.rectangle.fill")
                        Text("Watch Ad")
                    }
                    .font(.caption.weight(.bold))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    isReady ? AnyShapeStyle(Theme.oofGradient) : AnyShapeStyle(Color.white.opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .foregroundStyle(.white)
                .disabled(!isReady)
            }
        }
    }

    private var codesSection: some View {
        GlowCard(borderColor: .purple) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Redeem Code").font(.headline).foregroundStyle(.white)
                HStack {
                    TextField("Enter code", text: $codeText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                    Button("Redeem") {
                        viewModel.redeemCode(codeText)
                        codeText = ""
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.rebirthGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var backupSection: some View {
        GlowCard(borderColor: .blue) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Backup Save").font(.headline).foregroundStyle(.white)
                Text("Copy a backup code somewhere safe, or restore from one you saved earlier.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))

                Button("Copy Backup Code") {
                    guard let code = viewModel.exportSaveCode() else {
                        backupMessage = "Couldn't create a backup code."
                        return
                    }
                    UIPasteboard.general.string = code
                    backupMessage = "Copied to clipboard!"
                }
                .buttonStyle(PressableButtonStyle())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.oofGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.black)
                .font(.subheadline.weight(.bold))

                HStack {
                    TextField("Paste backup code", text: $importCodeText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    Button("Restore") {
                        guard !importCodeText.isEmpty else { return }
                        showImportConfirm = true
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.blue.opacity(importCodeText.isEmpty ? 0.2 : 0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
                    .disabled(importCodeText.isEmpty)
                }
                .confirmationDialog("Restoring will replace your current save. This can't be undone.", isPresented: $showImportConfirm, titleVisibility: .visible) {
                    Button("Restore Save", role: .destructive) {
                        let result = viewModel.importSaveCode(importCodeText)
                        switch result {
                        case .success:
                            backupMessage = "Save restored!"
                            importCodeText = ""
                        case .invalidCode:
                            backupMessage = "That backup code isn't valid."
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                if let message = backupMessage {
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
                // LazyVStack rather than a plain ForEach — this list has grown to 30+ rows
                // and only gets longer, so eagerly building every row on each sheet open
                // wastes work for whatever's off-screen. Still lazily loaded correctly here
                // since it sits inside MoreSheet's enclosing ScrollView.
                LazyVStack(alignment: .leading, spacing: 8) {
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
                            if let progressText = row.progressText {
                                Text(progressText)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
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

                Toggle(isOn: Binding(get: { viewModel.offlineReminderEnabled }, set: { _ in viewModel.toggleOfflineReminder() })) {
                    Text("Offline Reminder").foregroundStyle(.white)
                }
                .tint(.pink)

                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Text("Reset Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
