import Foundation

/// Static balance data for one Noob. Placeholder names/numbers — swap in the real
/// Noob Incremental Noob list (names, costs, outputs, unlock conditions) once available.
/// Per-save mutable state (level) lives separately in GeneratorState.
struct GeneratorDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let zoneID: String
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
        // Zone 1 — Spawn Island (always available)
        GeneratorDefinition(id: "starter_noob", name: "Starter Noob", zoneID: WorldCatalog.zone1ID, baseCost: GameBalance.startingCurrency, baseOutput: 0.8, unlockThreshold: 0),
        GeneratorDefinition(id: "farmer_noob", name: "Farmer Noob", zoneID: WorldCatalog.zone1ID, baseCost: 100, baseOutput: 7, unlockThreshold: 50),
        GeneratorDefinition(id: "builder_noob", name: "Builder Noob", zoneID: WorldCatalog.zone1ID, baseCost: 1_100, baseOutput: 55, unlockThreshold: 500),
        GeneratorDefinition(id: "miner_noob", name: "Miner Noob", zoneID: WorldCatalog.zone1ID, baseCost: 12_000, baseOutput: 320, unlockThreshold: 5_000),
        GeneratorDefinition(id: "tower_noob", name: "Tower Noob", zoneID: WorldCatalog.zone1ID, baseCost: 130_000, baseOutput: 1_800, unlockThreshold: 50_000),

        // Zone 2 — The Overworks (unlocks after your first Rebirth)
        GeneratorDefinition(id: "portal_noob", name: "Portal Noob", zoneID: WorldCatalog.zone2ID, baseCost: 1_500_000, baseOutput: 12_000, unlockThreshold: 0),
        GeneratorDefinition(id: "cosmic_noob", name: "Cosmic Noob", zoneID: WorldCatalog.zone2ID, baseCost: 20_000_000, baseOutput: 150_000, unlockThreshold: 500_000),
        GeneratorDefinition(id: "void_noob", name: "Void Noob", zoneID: WorldCatalog.zone2ID, baseCost: 300_000_000, baseOutput: 2_000_000, unlockThreshold: 5_000_000),

        // Zone 3 — The Ascension Spire (unlocks after 5 Rebirths)
        GeneratorDefinition(id: "ascended_noob", name: "Ascended Noob", zoneID: WorldCatalog.zone3ID, baseCost: 5_000_000_000, baseOutput: 25_000_000, unlockThreshold: 0),
        GeneratorDefinition(id: "ethereal_noob", name: "Ethereal Noob", zoneID: WorldCatalog.zone3ID, baseCost: 80_000_000_000, baseOutput: 350_000_000, unlockThreshold: 10_000_000),
        GeneratorDefinition(id: "divine_noob", name: "Divine Noob", zoneID: WorldCatalog.zone3ID, baseCost: 1_200_000_000_000, baseOutput: 5_000_000_000, unlockThreshold: 100_000_000)
    ]

    static func definition(for id: String) -> GeneratorDefinition? {
        all.first { $0.id == id }
    }

    static func all(inZone zoneID: String) -> [GeneratorDefinition] {
        all.filter { $0.zoneID == zoneID }
    }
}
