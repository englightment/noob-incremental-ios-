import Foundation

/// Static balance data for one Noob. Placeholder names/numbers — swap in the real
/// Noob Incremental Noob list (names, costs, outputs, unlock conditions) once available.
/// Per-save mutable state (level) lives separately in GeneratorState.
struct GeneratorDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let baseCost: Decimal
    let baseOutput: Decimal
    /// Lifetime Oof earned required before this Noob is purchasable. Always shown in the
    /// shop — greyed out with its unlock requirement until then, never hidden.
    let unlockThreshold: Decimal

    func isVisible(for state: GameState) -> Bool {
        state.lifetimeEarned >= unlockThreshold || (state.generators[id]?.level ?? 0) > 0
    }
}

enum GeneratorCatalog {
    static let all: [GeneratorDefinition] = [
        GeneratorDefinition(id: "starter_noob", name: "Starter Noob", baseCost: GameBalance.startingCurrency, baseOutput: 0.5, unlockThreshold: 0),
        GeneratorDefinition(id: "farmer_noob", name: "Farmer Noob", baseCost: 100, baseOutput: 4, unlockThreshold: 50),
        GeneratorDefinition(id: "builder_noob", name: "Builder Noob", baseCost: 1_100, baseOutput: 30, unlockThreshold: 500),
        GeneratorDefinition(id: "miner_noob", name: "Miner Noob", baseCost: 12_000, baseOutput: 180, unlockThreshold: 5_000),
        GeneratorDefinition(id: "tower_noob", name: "Tower Noob", baseCost: 130_000, baseOutput: 1_000, unlockThreshold: 50_000)
    ]

    static func definition(for id: String) -> GeneratorDefinition? {
        all.first { $0.id == id }
    }
}
