import Foundation

/// Advances game state by a fixed/variable elapsed duration. Pure and stateless so the
/// same function drives both the live foreground tick and the offline fast-forward step.
enum GameLoop {

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
        let outputMultiplier = UpgradeStore.outputMultiplier(state: state) * UpgradeStore.tickSpeedMultiplier(state: state)

        return GeneratorCatalog.all.reduce(Decimal(0)) { total, definition in
            let level = state.generators[definition.id]?.level ?? 0
            guard level > 0 else { return total }
            let output = Formulas.generatorOutput(
                baseOutput: definition.baseOutput,
                owned: level,
                outputMultiplier: outputMultiplier,
                prestigeMultiplier: state.prestigeMultiplier
            )
            return total + output
        }
    }
}
