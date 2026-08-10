import Foundation

/// Mirrors UpgradeStore/RebirthUpgradeStore but reads/writes state.runeShards and
/// state.runeLevels — Runes are bought with Rune Shards and survive rebirths.
enum RuneStore {

    static func level(_ definition: UpgradeDefinition, state: GameState) -> Int {
        state.runeLevels[definition.id] ?? 0
    }

    static func isMaxed(_ definition: UpgradeDefinition, state: GameState) -> Bool {
        level(definition, state: state) >= definition.maxLevel
    }

    static func cost(for definition: UpgradeDefinition, state: GameState) -> Decimal {
        Formulas.levelCost(base: definition.baseCost, owned: level(definition, state: state), growthRate: GameBalance.runeCostGrowthRate)
    }

    static func canAfford(_ definition: UpgradeDefinition, state: GameState) -> Bool {
        !isMaxed(definition, state: state) && state.runeShards >= cost(for: definition, state: state)
    }

    static func buyOne(_ definition: UpgradeDefinition, state: GameState) -> GameState {
        guard canAfford(definition, state: state) else { return state }
        var next = state
        next.runeShards -= cost(for: definition, state: state)
        next.runeLevels[definition.id] = level(definition, state: state) + 1
        return next
    }

    static func buyMax(_ definition: UpgradeDefinition, state: GameState) -> GameState {
        var next = state
        while canAfford(definition, state: next) {
            next = buyOne(definition, state: next)
        }
        return next
    }

    // MARK: - Aggregate effects consumed by GameLoop / RebirthSystem

    static func outputMultiplier(state: GameState) -> Decimal {
        RuneCatalog.all.reduce(Decimal(1)) { total, definition in
            guard case .outputMultiplier(let doublingInterval) = definition.effect else { return total }
            return total * UpgradeEffect.outputMultiplierValue(level: level(definition, state: state), doublingInterval: doublingInterval)
        }
    }

    static func rebirthGainMultiplier(state: GameState) -> Decimal {
        RuneCatalog.all.reduce(Decimal(1)) { total, definition in
            guard case .rebirthGainMultiplier(let growthRate) = definition.effect else { return total }
            return total * UpgradeEffect.rebirthGainMultiplierValue(level: level(definition, state: state), perLevelGrowthRate: growthRate)
        }
    }

    static func tickSpeedMultiplier(state: GameState) -> Decimal {
        let totalReductionSeconds = RuneCatalog.all.reduce(0.0) { total, definition -> Double in
            guard case .tickSpeedReduction(let secondsPerLevel) = definition.effect else { return total }
            return total + Double(level(definition, state: state)) * secondsPerLevel
        }
        let effectiveTick = max(GameBalance.minimumNoobTickSeconds, GameBalance.baseNoobTickSeconds - totalReductionSeconds)
        return Decimal(GameBalance.baseNoobTickSeconds / effectiveTick)
    }

    static func costDiscountMultiplier(state: GameState) -> Decimal {
        RuneCatalog.all.reduce(Decimal(1)) { total, definition in
            guard case .costDiscount(let perLevelPercent) = definition.effect else { return total }
            return total * UpgradeEffect.costDiscountMultiplierValue(level: level(definition, state: state), perLevelPercent: perLevelPercent)
        }
    }

    static func flatOutputBonus(state: GameState) -> Decimal {
        RuneCatalog.all.reduce(Decimal(0)) { total, definition in
            guard case .flatOutputBonus(let perLevel) = definition.effect else { return total }
            return total + UpgradeEffect.flatOutputBonusValue(level: level(definition, state: state), perLevel: perLevel)
        }
    }
}
