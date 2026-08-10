import Foundation

/// Advances game state by a fixed/variable elapsed duration. Pure and stateless so the
/// same function drives both the live foreground tick and the offline fast-forward step.
enum GameLoop {

    static func tick(_ state: GameState, elapsed: TimeInterval, now: Date = Date()) -> GameState {
        guard elapsed > 0 else { return state }

        var next = state
        let passiveIncome = passiveIncomePerSecond(state, now: now) * Decimal(elapsed)
        if passiveIncome > 0 {
            next.currency += passiveIncome
            next.lifetimeEarned += passiveIncome
        }
        next.totalPlayTime += elapsed
        return next
    }

    static func passiveIncomePerSecond(_ state: GameState, now: Date = Date()) -> Decimal {
        let outputMultiplier = UpgradeStore.outputMultiplier(state: state)
            * UpgradeStore.tickSpeedMultiplier(state: state)
            * RebirthUpgradeStore.outputMultiplier(state: state)
            * RebirthUpgradeStore.tickSpeedMultiplier(state: state)
            * AchievementStore.outputMultiplier(state: state)
            * BoostSystem.activeMultiplier(state: state, now: now)
            * AdBoostSystem.combinedMultiplier(state: state, now: now)
            * RuneStore.outputMultiplier(state: state)
            * RuneStore.tickSpeedMultiplier(state: state)

        let generatorTotal = GeneratorCatalog.all.reduce(Decimal(0)) { total, definition in
            let level = state.generators[definition.id]?.level ?? 0
            guard level > 0 else { return total }
            let output = Formulas.generatorOutput(
                baseOutput: definition.baseOutput,
                owned: level,
                outputMultiplier: outputMultiplier
            )
            return total + output
        }

        // Flat bonuses are intentionally unmultiplied — a distinct, simple upgrade flavor.
        let flatBonus = UpgradeStore.flatOutputBonus(state: state)
            + RebirthUpgradeStore.flatOutputBonus(state: state)
            + RuneStore.flatOutputBonus(state: state)
        return generatorTotal + flatBonus
    }
}
