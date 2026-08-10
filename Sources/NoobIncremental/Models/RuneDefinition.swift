import Foundation

/// Runes reuse UpgradeDefinition/UpgradeEffect — same "level costs X, does Y" shape as the
/// other two shops, just bought with Rune Shards instead of Oof or Rebirth currency.
enum RuneCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "rune_oof", name: "Rune of Oof", baseCost: 5, maxLevel: 10, effect: .outputMultiplier(doublingInterval: 3)),
        UpgradeDefinition(id: "rune_rebirth", name: "Rune of Rebirth", baseCost: 8, maxLevel: 10, effect: .rebirthGainMultiplier(perLevelGrowthRate: 1.15)),
        UpgradeDefinition(id: "rune_haste", name: "Rune of Haste", baseCost: 6, maxLevel: 10, effect: .tickSpeedReduction(secondsPerLevel: 0.05))
    ]

    static func definition(for id: String) -> UpgradeDefinition? {
        all.first { $0.id == id }
    }
}
