import SwiftUI

/// Shared visual building blocks pulled out of ContentView.swift so they can be reused
/// by the 2D overworld's station popups (see OverworldView.swift, GeneratorStationPopupView.swift)
/// without forking near-duplicates that would drift out of sync over time.
enum Theme {
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

// MARK: - Glass panel (shared card/banner styling)

struct GlassPanel: ViewModifier {
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

extension View {
    func glassPanel(tint: Color, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassPanel(tint: tint, cornerRadius: cornerRadius))
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum BuyQuantity: String, CaseIterable, Identifiable {
    case one = "x1", ten = "x10", hundred = "x100", max = "Max"
    var id: String { rawValue }
}

// MARK: - Card container

struct GlowCard<Content: View>: View {
    let borderColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .glassPanel(tint: borderColor, cornerRadius: 18)
    }
}

struct GeneratorRowView: View {
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
                    .accessibilityLabel(quantity == .max ? "Buy max \(data.name)" : "Upgrade \(data.name)")
                    .accessibilityValue(costText)
                    .accessibilityHint(canAfford ? "" : "Not enough Oof")
                }
            }
        }
        .opacity(data.isLocked ? 0.55 : 1.0)
        .modifier(LockedAccessibilitySummary(isLocked: data.isLocked, name: data.name, unlockText: data.unlockText))
    }
}

/// Locked generator/upgrade rows have no interactive button for VoiceOver to land on, so
/// without this the whole row reads as a jumble of static text with no indication of why
/// it's greyed out. Collapses to a single "name, locked — unlockText" element only when
/// locked; unlocked rows keep their normal per-child navigation (name, level, Upgrade button).
struct LockedAccessibilitySummary: ViewModifier {
    let isLocked: Bool
    let name: String
    let unlockText: String

    func body(content: Content) -> some View {
        if isLocked {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(name), locked")
                .accessibilityHint(unlockText)
        } else {
            content
        }
    }
}
