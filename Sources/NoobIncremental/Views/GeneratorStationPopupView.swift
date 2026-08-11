import SwiftUI

/// The buy popup shown when the player taps the interact prompt at a Noob generator's
/// station in the overworld. Wraps the existing (shared, see SharedRowComponents.swift)
/// GeneratorRowView for just that one generator — same buy button, cost text, and
/// accessibility labels/hints the old Noobs tab already had, just reached by walking up
/// to a station instead of switching tabs.
struct GeneratorStationPopupView: View {
    let generator: GeneratorRowViewData
    let onBuy: (Int) -> Void
    let onBuyMax: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: BuyQuantity = .one

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Picker("Quantity", selection: $quantity) {
                        ForEach(BuyQuantity.allCases) { q in
                            Text(q.rawValue).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)

                    GeneratorRowView(data: generator, quantity: quantity) {
                        switch quantity {
                        case .one: onBuy(1)
                        case .ten: onBuy(10)
                        case .hundred: onBuy(100)
                        case .max: onBuyMax()
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(generator.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
