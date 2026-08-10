import Foundation

/// QoL auto-buy: each call levels up whichever visible, affordable Noob is currently
/// cheapest. A no-op when disabled or nothing is affordable.
enum AutoBuyStore {
    static func step(state: GameState) -> GameState {
        guard state.autoBuyEnabled else { return state }

        let affordable = GeneratorCatalog.all
            .filter { $0.isVisible(for: state) && GeneratorStore.canAfford($0, state: state) }
            .sorted { GeneratorStore.cost(for: $0, state: state) < GeneratorStore.cost(for: $1, state: state) }

        guard let cheapest = affordable.first else { return state }
        return GeneratorStore.buy(cheapest, state: state)
    }
}
