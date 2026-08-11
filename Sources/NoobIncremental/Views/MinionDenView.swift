import SwiftUI

/// The Minion Den — Zone 2's station for viewing/equipping Minions. Replaces the old
/// Settings-buried minionsSection (removed from MoreSheet in the same change that added
/// this, so there's never a moment where Minions have no UI at all). Unlock logic itself is
/// unchanged — each Minion still ties to an existing Achievement id via
/// MinionSystem.syncOwnership; only where the player goes to see/equip them moved.
struct MinionDenSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Minion Den").font(.title2.weight(.bold)).foregroundStyle(.white)
                            Spacer()
                            Text("\(viewModel.equippedMinionCount)/\(viewModel.maxEquippedMinions) equipped")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        ForEach(viewModel.minionRows) { minion in
                            minionRow(minion)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Minion Den")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func minionRow(_ minion: MinionRowViewData) -> some View {
        let atCap = !minion.isEquipped && viewModel.equippedMinionCount >= viewModel.maxEquippedMinions

        return GlowCard(borderColor: .mint) {
            HStack(spacing: 10) {
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
    }
}
