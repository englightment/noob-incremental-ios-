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
        let price = cost(for: definition, state: state)
        guard state.currency >= price else { return state }

        var next = state
        next.currency -= price

        var generatorState = next.generators[definition.id] ?? GeneratorState(id: definition.id)
        generatorState.level += 1
        generatorState.isUnlocked = true
        next.generators[definition.id] = generatorState

        return next
    }
}
