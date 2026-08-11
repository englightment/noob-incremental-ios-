import SwiftUI

/// The player's on-screen 2D avatar in the overworld — a generated pixel-art chibi Noob
/// sprite (PlayerSprite in Assets.xcassets). `.interpolation(.none)` keeps the pixel edges
/// hard when the sprite is scaled up, instead of SwiftUI's default smoothing turning it
/// blurry.
struct PlayerAvatarView: View {
    var size: CGFloat = 56
    var facingRight: Bool = true

    var body: some View {
        Image("PlayerSprite")
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(x: facingRight ? 1 : -1, y: 1)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
    }
}

#Preview {
    PlayerAvatarView(size: 90)
        .padding()
        .background(Color.black)
}
