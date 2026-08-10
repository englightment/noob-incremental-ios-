import Foundation

/// What a global upgrade does, and how to describe its next level for the shop UI.
/// Placeholder numbers — real growth rates/caps from the source game go here once known.
enum UpgradeEffect: Equatable {
    /// Total output multiplier follows multiplier(level) = 2^(level / doublingInterval).
    case outputMultiplier(doublingInterval: Int)
    /// Each level shaves `secondsPerLevel` off the Noob production tick.
    case tickSpeedReduction(secondsPerLevel: TimeInterval)
    /// Total multiplier on rebirth-currency gain follows multiplier(level) = growthRate^level.
    case rebirthGainMultiplier(perLevelGrowthRate: Double)
    /// Reduces every Noob's cost by perLevelPercent per level (floored at 50% off).
    case costDiscount(perLevelPercent: Double)
    /// Adds a flat, unmultiplied amount straight to total Oof/sec per level.
    case flatOutputBonus(perLevel: Decimal)

    static func outputMultiplierValue(level: Int, doublingInterval: Int) -> Decimal {
        guard doublingInterval > 0 else { return 1 }
        let exponent = Double(level) / Double(doublingInterval)
        return Decimal(pow(2.0, exponent))
    }

    static func rebirthGainMultiplierValue(level: Int, perLevelGrowthRate: Double) -> Decimal {
        Decimal(pow(perLevelGrowthRate, Double(level)))
    }

    static func costDiscountMultiplierValue(level: Int, perLevelPercent: Double, floor: Double = 0.5) -> Decimal {
        Decimal(max(floor, 1.0 - perLevelPercent * Double(level)))
    }

    static func flatOutputBonusValue(level: Int, perLevel: Decimal) -> Decimal {
        perLevel * Decimal(level)
    }

    /// "current -> next level" text matching the source game's upgrade cards.
    func description(atLevel level: Int) -> String {
        switch self {
        case .outputMultiplier(let doublingInterval):
            let current = Self.outputMultiplierValue(level: level, doublingInterval: doublingInterval)
            let next = Self.outputMultiplierValue(level: level + 1, doublingInterval: doublingInterval)
            return "x\(NumberFormatting.format(current)) \u{2192} x\(NumberFormatting.format(next))"
        case .tickSpeedReduction(let secondsPerLevel):
            let current = Double(level) * secondsPerLevel
            let next = Double(level + 1) * secondsPerLevel
            return String(format: "-%.1fs \u{2192} -%.1fs", current, next)
        case .rebirthGainMultiplier(let growthRate):
            let current = Self.rebirthGainMultiplierValue(level: level, perLevelGrowthRate: growthRate)
            let next = Self.rebirthGainMultiplierValue(level: level + 1, perLevelGrowthRate: growthRate)
            return "x\(NumberFormatting.format(current)) \u{2192} x\(NumberFormatting.format(next))"
        case .costDiscount(let perLevelPercent):
            let current = (1 - Self.costDiscountMultiplierValue(level: level, perLevelPercent: perLevelPercent)) * 100
            let next = (1 - Self.costDiscountMultiplierValue(level: level + 1, perLevelPercent: perLevelPercent)) * 100
            return "-\(NumberFormatting.format(current))% cost \u{2192} -\(NumberFormatting.format(next))% cost"
        case .flatOutputBonus(let perLevel):
            let current = Self.flatOutputBonusValue(level: level, perLevel: perLevel)
            let next = Self.flatOutputBonusValue(level: level + 1, perLevel: perLevel)
            return "+\(NumberFormatting.format(current))/sec \u{2192} +\(NumberFormatting.format(next))/sec"
        }
    }
}

struct UpgradeDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let baseCost: Decimal
    let maxLevel: Int
    let effect: UpgradeEffect
}

/// Bought with Oof, cheap and frequent.
enum UpgradeCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "more_oof", name: "More Oof", baseCost: 75, maxLevel: 50, effect: .outputMultiplier(doublingInterval: 15)),
        UpgradeDefinition(id: "faster_noobs", name: "Faster Noobs", baseCost: 10_000, maxLevel: 5, effect: .tickSpeedReduction(secondsPerLevel: 0.1)),
        UpgradeDefinition(id: "bulk_discount", name: "Bulk Discount", baseCost: 500, maxLevel: 20, effect: .costDiscount(perLevelPercent: 0.02)),
        UpgradeDefinition(id: "noob_value", name: "Noob Value", baseCost: 300, maxLevel: 25, effect: .flatOutputBonus(perLevel: 5))
    ]

    static func definition(for id: String) -> UpgradeDefinition? {
        all.first { $0.id == id }
    }
}

/// Bought with Rebirth currency, rare and powerful — survives resets.
enum RebirthUpgradeCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "rebirth_more_oof", name: "More Oof", baseCost: 12_400, maxLevel: 6, effect: .outputMultiplier(doublingInterval: 1)),
        UpgradeDefinition(id: "rebirth_more_rebirth", name: "More Rebirth", baseCost: 142, maxLevel: 10, effect: .rebirthGainMultiplier(perLevelGrowthRate: 1.25)),
        UpgradeDefinition(id: "rebirth_speed", name: "Rebirth Speed", baseCost: 500, maxLevel: 8, effect: .tickSpeedReduction(secondsPerLevel: 0.08)),
        UpgradeDefinition(id: "rebirth_mega_value", name: "Mega Value", baseCost: 300, maxLevel: 15, effect: .flatOutputBonus(perLevel: 500))
    ]

    static func definition(for id: String) -> UpgradeDefinition? {
        all.first { $0.id == id }
    }
}
