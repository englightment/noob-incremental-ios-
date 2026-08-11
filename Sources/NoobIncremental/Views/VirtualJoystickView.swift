import SwiftUI

/// A bottom-corner virtual joystick: drag the nub to walk, release to stop. Exposes a
/// direction vector already clamped to unit magnitude (see PlayerMovementSystem) so
/// OverworldView can feed it straight into PlayerMovementSystem.move without renormalizing.
/// Partial drags produce a proportionally shorter vector (analog-stick feel) rather than
/// snapping straight to full speed.
struct VirtualJoystickView: View {
    var diameter: CGFloat = 120
    @Binding var direction: CGVector
    @Binding var isActive: Bool

    @State private var nubOffset: CGSize = .zero

    private var radius: CGFloat { diameter / 2 }
    // Small absolute-point tolerance so tiny/accidental touches don't register as movement.
    private let deadZonePoints: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5))
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: diameter * 0.42, height: diameter * 0.42)
                .offset(nubOffset)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let raw = CGVector(dx: value.translation.width, dy: value.translation.height)
                    let rawMagnitude = (raw.dx * raw.dx + raw.dy * raw.dy).squareRoot()
                    guard rawMagnitude > deadZonePoints else {
                        direction = .zero
                        isActive = false
                        nubOffset = .zero
                        return
                    }
                    let boundedToBase = PlayerMovementSystem.clampMagnitude(raw, to: radius)
                    direction = CGVector(dx: boundedToBase.dx / radius, dy: boundedToBase.dy / radius)
                    isActive = true
                    nubOffset = CGSize(width: boundedToBase.dx, height: boundedToBase.dy)
                }
                .onEnded { _ in
                    direction = .zero
                    isActive = false
                    withAnimation(.easeOut(duration: 0.15)) {
                        nubOffset = .zero
                    }
                }
        )
        // No VoiceOver equivalent exists for this control — see the "fully replace, no
        // accessibility fallback" decision in the approved overworld plan.
        .accessibilityHidden(true)
    }
}
