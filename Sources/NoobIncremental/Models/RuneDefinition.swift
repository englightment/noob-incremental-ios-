import Foundation

/// Runes reuse UpgradeDefinition/UpgradeEffect — same "level costs X, does Y" shape as the
/// other two shops, just bought with Rune Shards instead of Oof or Rebirth currency.
enum RuneCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "rune_oof", name: "Rune of Oof", baseCost: 5, maxLevel: 10, effect: .outputMultiplier(doublingInterval: 3)),
        UpgradeDefinition(id: "rune_rebirth", name: "Rune of Rebirth", baseCost: 8, maxLevel: 10, effect: .rebirthGainMultiplier(perLevelGrowthRate: 1.15)),
        UpgradeDefinition(id: "rune_haste", name: "Rune of Haste", baseCost: 6, maxLevel: 10, effect: .tickSpeedReduction(secondsPerLevel: 0.05)),
        UpgradeDefinition(id: "rune_wealth", name: "Rune of Wealth", baseCost: 7, maxLevel: 10, effect: .costDiscount(perLevelPercent: 0.03)),
        UpgradeDefinition(id: "rune_bounty", name: "Rune of Bounty", baseCost: 6, maxLevel: 10, effect: .flatOutputBonus(perLevel: 50)),
        UpgradeDefinition(id: "rune_kinship", name: "Rune of Kinship", baseCost: 20, maxLevel: 2, effect: .minionSlotBonus(perLevel: 1))
    ]

    static func definition(for id: String) -> UpgradeDefinition? {
        all.first { $0.id == id }
    }
}
