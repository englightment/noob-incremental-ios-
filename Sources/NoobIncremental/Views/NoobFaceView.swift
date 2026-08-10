import SwiftUI

/// Hand-drawn mascot face (matches the app icon) — pure vector, no image assets, so it
/// scales crisply at any size and stays in sync with the icon if the palette ever changes.
struct NoobFaceView: View {
    var size: CGFloat = 60
    var excited: Bool = false

    private let ink = Color(red: 0.10, green: 0.06, blue: 0.19)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.21)
                .fill(LinearGradient(
                    colors: [Color(red: 1.0, green: 0.88, blue: 0.4), Color(red: 1.0, green: 0.69, blue: 0.13)],
                    startPoint: .top, endPoint: .bottom
                ))

            HStack(spacing: size * 0.24) {
                eye
                eye
            }
            .offset(y: -size * 0.1)

            SmileShape(excited: excited)
                .stroke(ink, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round))
                .frame(width: size * 0.36, height: size * 0.2)
                .offset(y: size * 0.15)

            HStack(spacing: size * 0.44) {
                cheek
                cheek
            }
            .offset(y: size * 0.15)
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        ZStack {
            Ellipse()
                .fill(ink)
                .frame(width: size * 0.13, height: size * 0.19)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.02, y: -size * 0.04)
        }
    }

    private var cheek: some View {
        Ellipse()
            .fill(Color(red: 1.0, green: 0.43, blue: 0.43).opacity(0.35))
            .frame(width: size * 0.12, height: size * 0.08)
    }
}

private struct SmileShape: Shape {
    var excited: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.minX, y: rect.minY)
        let end = CGPoint(x: rect.maxX, y: rect.minY)
        let control = CGPoint(x: rect.midX, y: rect.maxY * (excited ? 1.7 : 1.0))
        p.move(to: start)
        p.addQuadCurve(to: end, control: control)
        return p
    }
}

#Preview {
    HStack(spacing: 16) {
        NoobFaceView(size: 90)
        NoobFaceView(size: 90, excited: true)
    }
    .padding()
    .background(Color.black)
}
