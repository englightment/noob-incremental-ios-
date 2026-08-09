import Foundation

/// What a global upgrade does, and how to describe its next level for the shop UI.
/// Placeholder numbers — real growth rates/caps from the source game go here once known.
enum UpgradeEffect: Equatable {
    /// Total output multiplier follows multiplier(level) = 2^(level / doublingInterval).
    case outputMultiplier(doublingInterval: Int)
    /// Each level shaves `secondsPerLevel` off the Noob production tick.
    case tickSpeedReduction(secondsPerLevel: TimeInterval)

    static func outputMultiplierValue(level: Int, doublingInterval: Int) -> Decimal {
        guard doublingInterval > 0 else { return 1 }
        let exponent = Double(level) / Double(doublingInterval)
        return Decimal(pow(2.0, exponent))
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

enum UpgradeCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "more_oof", name: "More Oof", baseCost: 75, maxLevel: 50, effect: .outputMultiplier(doublingInterval: 15)),
        UpgradeDefinition(id: "faster_noobs", name: "Faster Noobs", baseCost: 10_000, maxLevel: 5, effect: .tickSpeedReduction(secondsPerLevel: 0.1))
    ]

    static func definition(for id: String) -> UpgradeDefinition? {
        all.first { $0.id == id }
    }
}
