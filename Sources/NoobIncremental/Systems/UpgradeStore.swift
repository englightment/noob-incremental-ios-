import Foundation

/// Pure purchase logic for global upgrades, plus the aggregate multipliers GameLoop needs.
enum UpgradeStore {

    static func level(_ definition: UpgradeDefinition, state: GameState) -> Int {
        state.upgradeLevels[definition.id] ?? 0
    }

    static func isMaxed(_ definition: UpgradeDefinition, state: GameState) -> Bool {
        level(definition, state: state) >= definition.maxLevel
    }

    static func cost(for definition: UpgradeDefinition, state: GameState) -> Decimal {
        Formulas.levelCost(base: definition.baseCost, owned: level(definition, state: state))
    }

    static func canAfford(_ definition: UpgradeDefinition, state: GameState) -> Bool {
        !isMaxed(definition, state: state) && state.currency >= cost(for: definition, state: state)
    }

    /// Returns state unchanged if maxed out or can't be afforded.
    static func buyOne(_ definition: UpgradeDefinition, state: GameState) -> GameState {
        guard canAfford(definition, state: state) else { return state }
        var next = state
        next.currency -= cost(for: definition, state: state)
        next.upgradeLevels[definition.id] = level(definition, state: state) + 1
        return next
    }

    /// Repeatedly buys the next level until unaffordable or maxed. Bounded by `maxLevel`.
    static func buyMax(_ definition: UpgradeDefinition, state: GameState) -> GameState {
        var next = state
        while canAfford(definition, state: next) {
            next = buyOne(definition, state: next)
        }
        return next
    }

    // MARK: - Aggregate effects consumed by GameLoop

    static func outputMultiplier(state: GameState) -> Decimal {
        UpgradeCatalog.all.reduce(Decimal(1)) { total, definition in
            guard case .outputMultiplier(let doublingInterval) = definition.effect else { return total }
            return total * UpgradeEffect.outputMultiplierValue(level: level(definition, state: state), doublingInterval: doublingInterval)
        }
    }

    static func tickSpeedMultiplier(state: GameState) -> Decimal {
        let totalReductionSeconds = UpgradeCatalog.all.reduce(0.0) { total, definition -> Double in
            guard case .tickSpeedReduction(let secondsPerLevel) = definition.effect else { return total }
            return total + Double(level(definition, state: state)) * secondsPerLevel
        }
        let effectiveTick = max(GameBalance.minimumNoobTickSeconds, GameBalance.baseNoobTickSeconds - totalReductionSeconds)
        return Decimal(GameBalance.baseNoobTickSeconds / effectiveTick)
    }
}
