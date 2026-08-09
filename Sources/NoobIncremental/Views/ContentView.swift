import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var tapScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 32) {
            if let earnings = viewModel.lastOfflineEarnings {
                OfflineEarningsBanner(amount: earnings) {
                    viewModel.dismissOfflineEarningsBanner()
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text(viewModel.formattedCurrency)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.formattedCurrency)
                Text("Noobs")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: handleTap) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 180, height: 180)
                    .overlay(
                        Text("Tap!")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    )
                    .scaleEffect(tapScale)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .onAppear { viewModel.start() }
    }

    private func handleTap() {
        viewModel.tap()
        withAnimation(.easeOut(duration: 0.08)) {
            tapScale = 0.9
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4).delay(0.08)) {
            tapScale = 1.0
        }
    }
}

private struct OfflineEarningsBanner: View {
    let amount: Decimal
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text("While you were away: +\(NumberFormatting.format(amount)) Noobs")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button("Dismiss", action: onDismiss)
                .font(.caption)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView(viewModel: GameViewModel())
}
