import Foundation

/// Pure purchase logic for leveling up Noobs, built on top of Formulas' cost curve.
enum GeneratorStore {

    static func level(_ definition: GeneratorDefinition, state: GameState) -> Int {
        state.generators[definition.id]?.level ?? 0
    }

    /// Noob base cost after the "Bulk Discount" upgrade (if any) is applied. Threading the
    /// discount through the *base* rather than the final price keeps maxAffordableLevels'
    /// closed-form math correct — it needs the real per-level cost, not a post-hoc discount.
    private static func discountedBaseCost(_ definition: GeneratorDefinition, state: GameState) -> Decimal {
        definition.baseCost * UpgradeStore.costDiscountMultiplier(state: state)
    }

    static func cost(for definition: GeneratorDefinition, state: GameState) -> Decimal {
        Formulas.levelCost(base: discountedBaseCost(definition, state: state), owned: level(definition, state: state))
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
        let price = Formulas.bulkLevelCost(base: discountedBaseCost(definition, state: state), owned: owned, quantity: quantity)
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
        Formulas.bulkLevelCost(base: discountedBaseCost(definition, state: state), owned: level(definition, state: state), quantity: quantity)
    }

    static func canAffordQuantity(_ definition: GeneratorDefinition, quantity: Int, state: GameState) -> Bool {
        state.currency >= costForQuantity(definition, quantity: quantity, state: state)
    }

    /// How many more levels are affordable right now — accounts for the Bulk Discount
    /// upgrade, unlike calling Formulas.maxAffordableLevels directly with the raw base cost.
    static func maxAffordableCount(_ definition: GeneratorDefinition, state: GameState) -> Int {
        Formulas.maxAffordableLevels(base: discountedBaseCost(definition, state: state), owned: level(definition, state: state), availableCurrency: state.currency)
    }

    /// Buys as many levels as currently affordable — the one case where "best effort" is the
    /// intent, not a bug: that's what "Max" means.
    static func buyMax(_ definition: GeneratorDefinition, state: GameState) -> GameState {
        buyQuantity(definition, quantity: maxAffordableCount(definition, state: state), state: state)
    }
}
