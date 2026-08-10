import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xFraction: Double
    let color: Color
    let width: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
}

/// Full-overlay falling confetti burst for celebratory moments (milestones, achievements).
/// Pure vector shapes animating via SwiftUI — no image/particle assets needed.
struct ConfettiView: View {
    let pieces: [ConfettiPiece]
    @State private var animate = false

    static func randomBurst(count: Int = 44) -> [ConfettiPiece] {
        let palette: [Color] = [.pink, .yellow, .purple, .cyan, .orange, .green, .white]
        return (0..<count).map { _ in
            ConfettiPiece(
                xFraction: Double.random(in: 0...1),
                color: palette.randomElement() ?? .pink,
                width: CGFloat.random(in: 6...13),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.35),
                duration: Double.random(in: 1.0...1.8)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.width * 0.5)
                        .rotationEffect(.degrees(animate ? piece.rotation + 220 : piece.rotation))
                        .position(
                            x: piece.xFraction * geo.size.width,
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}
