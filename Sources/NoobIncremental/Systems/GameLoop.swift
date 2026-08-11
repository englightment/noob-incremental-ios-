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
            * RebirthUpgradeStore.outputMultiplier(state: state)
            * AchievementStore.outputMultiplier(state: state)
            * BoostSystem.activeMultiplier(state: state, now: now)
            * AdBoostSystem.combinedMultiplier(state: state, now: now)
            * RuneStore.outputMultiplier(state: state)
            * MinionSystem.outputMultiplier(state: state)
            * combinedTickSpeedMultiplier(state: state)

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

    /// Tick-speed reduction is additive against one shared base tick, unlike every other
    /// bonus type (which stacks multiplicatively). Combining the three shops' reduction
    /// seconds here — rather than multiplying each shop's own tickSpeedMultiplier() together,
    /// which treats each shop as if it were the *only* source and overstates/understates the
    /// combined effect — keeps the real speedup matching what each upgrade's "-Xs" description
    /// promises.
    private static func combinedTickSpeedMultiplier(state: GameState) -> Decimal {
        let totalReductionSeconds = tickReductionSeconds(UpgradeCatalog.all, levels: state.upgradeLevels)
            + tickReductionSeconds(RebirthUpgradeCatalog.all, levels: state.rebirthUpgradeLevels)
            + tickReductionSeconds(RuneCatalog.all, levels: state.runeLevels)
        let effectiveTick = max(GameBalance.minimumNoobTickSeconds, GameBalance.baseNoobTickSeconds - totalReductionSeconds)
        return Decimal(GameBalance.baseNoobTickSeconds / effectiveTick)
    }

    private static func tickReductionSeconds(_ definitions: [UpgradeDefinition], levels: [String: Int]) -> Double {
        definitions.reduce(0.0) { total, definition in
            guard case .tickSpeedReduction(let secondsPerLevel) = definition.effect else { return total }
            let level = levels[definition.id] ?? 0
            return total + Double(level) * secondsPerLevel
        }
    }
}
