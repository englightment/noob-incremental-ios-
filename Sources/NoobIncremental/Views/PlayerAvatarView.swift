import SwiftUI

/// The player's on-screen 2D avatar in the overworld — reuses the existing NoobFaceView
/// mascot (matches the app icon) with a simple drawn torso, following this project's
/// established "no image assets, pure SwiftUI Shapes" convention.
struct PlayerAvatarView: View {
    var size: CGFloat = 56
    var facingRight: Bool = true

    var body: some View {
        VStack(spacing: -size * 0.06) {
            NoobFaceView(size: size)
            torso
        }
        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
        .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
    }

    private var torso: some View {
        RoundedRectangle(cornerRadius: size * 0.14)
            .fill(LinearGradient(
                colors: [Color(red: 1.0, green: 0.69, blue: 0.13), Color(red: 0.85, green: 0.48, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: size * 0.58, height: size * 0.46)
    }
}

#Preview {
    PlayerAvatarView(size: 90)
        .padding()
        .background(Color.black)
}
