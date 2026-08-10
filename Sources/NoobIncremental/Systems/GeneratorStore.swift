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

    /// Returns state unchanged if the purchase can't be afforded.
    static func buy(_ definition: GeneratorDefinition, state: GameState) -> GameState {
        buyQuantity(definition, quantity: 1, state: state)
    }

    /// Buys up to `quantity` levels at once. Buys as many as affordable if funds run out
    /// partway — never partially fails.
    static func buyQuantity(_ definition: GeneratorDefinition, quantity: Int, state: GameState) -> GameState {
        guard quantity > 0 else { return state }
        let owned = level(definition, state: state)
        let affordable = min(quantity, Formulas.maxAffordableLevels(base: definition.baseCost, owned: owned, availableCurrency: state.currency))
        guard affordable > 0 else { return state }

        var next = state
        next.currency -= Formulas.bulkLevelCost(base: definition.baseCost, owned: owned, quantity: affordable)

        var generatorState = next.generators[definition.id] ?? GeneratorState(id: definition.id)
        generatorState.level += affordable
        generatorState.isUnlocked = true
        next.generators[definition.id] = generatorState

        return next
    }

    /// Buys as many levels as currently affordable. Generators have no level cap.
    static func buyMax(_ definition: GeneratorDefinition, state: GameState) -> GameState {
        let owned = level(definition, state: state)
        let affordable = Formulas.maxAffordableLevels(base: definition.baseCost, owned: owned, availableCurrency: state.currency)
        return buyQuantity(definition, quantity: affordable, state: state)
    }
}
