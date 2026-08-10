import Foundation

/// Pure purchase logic for leveling up Noobs, built on top of Formulas' cost curve.
enum GeneratorStore {

    static func level(_ definition: GeneratorDefinition, state: GameState) -> Int {
        state.generators[definition.id]?.level ?? 0
    }

    static func cost(for definition: GeneratorDefinition, state: GameState) -> Decimal {
        Formulas.levelCost(base: definition.baseCost, owned: level(definition, state: state))
    }

    static func canAfford(_ definition: GeneratorDefinition, state: GameState) -> Bool {
        state.currency >= cost(for: definition, state: state)
    }

    static func buy(_ definition: GeneratorDefinition, state: GameState) -> GameState {
        buyQuantity(definition, quantity: 1, state: state)
    }

    /// All-or-nothing: buys exactly `quantity` levels if (and only if) the full bulk cost is
    /// affordable right now. Returns state unchanged otherwise — no silent partial fill, so a
    /// player who picks x10 either gets 10 or is clearly told (via cost/canAfford) they can't.
    static func buyQuantity(_ definition: GeneratorDefinition, quantity: Int, state: GameState) -> GameState {
        guard quantity > 0 else { return state }
        let owned = level(definition, state: state)
        let price = Formulas.bulkLevelCost(base: definition.baseCost, owned: owned, quantity: quantity)
        guard state.currency >= price else { return state }

        var next = state
        next.currency -= price

        var generatorState = next.generators[definition.id] ?? GeneratorState(id: definition.id)
        generatorState.level += quantity
        generatorState.isUnlocked = true
        next.generators[definition.id] = generatorState

        return next
    }

    static func costForQuantity(_ definition: GeneratorDefinition, quantity: Int, state: GameState) -> Decimal {
        Formulas.bulkLevelCost(base: definition.baseCost, owned: level(definition, state: state), quantity: quantity)
    }

    static func canAffordQuantity(_ definition: GeneratorDefinition, quantity: Int, state: GameState) -> Bool {
        state.currency >= costForQuantity(definition, quantity: quantity, state: state)
    }

    /// Buys as many levels as currently affordable — the one case where "best effort" is the
    /// intent, not a bug: that's what "Max" means.
    static func buyMax(_ definition: GeneratorDefinition, state: GameState) -> GameState {
        let owned = level(definition, state: state)
        let affordable = Formulas.maxAffordableLevels(base: definition.baseCost, owned: owned, availableCurrency: state.currency)
        return buyQuantity(definition, quantity: affordable, state: state)
    }
}
