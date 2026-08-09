import Foundation

/// Advances game state by a fixed/variable elapsed duration. Pure and stateless so the
/// same function drives both the live foreground tick and the offline fast-forward step.
enum GameLoop {

    /// Registry of generator definitions is intentionally absent for now — no generators
    /// exist yet (feature priority #2). Passive income is 0 until generators are added,
    /// at which point this switches to summing `Formulas.generatorOutput` per definition.
    static func tick(_ state: GameState, elapsed: TimeInterval) -> GameState {
        guard elapsed > 0 else { return state }

        var next = state
        let passiveIncome = passiveIncomePerSecond(state) * Decimal(elapsed)
        if passiveIncome > 0 {
            next.currency += passiveIncome
            next.lifetimeEarned += passiveIncome
        }
        next.totalPlayTime += elapsed
        return next
    }

    static func passiveIncomePerSecond(_ state: GameState) -> Decimal {
        // No generators defined yet; placeholder for when GeneratorDefinition catalog lands.
        0
    }

    static func applyTap(_ state: GameState) -> GameState {
        var next = state
        let gain = Formulas.tapValue(
            baseValue: state.tapBaseValue,
            tapMultiplier: state.tapMultiplier,
            prestigeMultiplier: state.prestigeMultiplier
        )
        next.currency += gain
        next.lifetimeEarned += gain
        return next
    }
}
