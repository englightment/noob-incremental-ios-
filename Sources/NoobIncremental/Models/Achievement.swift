import Foundation

enum AchievementCondition: Equatable {
    case lifetimeEarned(Decimal)
    case rebirths(Int)
    case totalNoobLevels(Int)
    case allNoobsOwned
    case upgradeMaxed(String)
    case codeRedeemed
    case streakDays(Int)
    case zoneNoobLevels(zoneID: String, total: Int)
    case allRunesOwned
    case allMinionsOwned
    case allZoneNoobsOwned(zoneID: String)
}

struct AchievementDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let condition: AchievementCondition
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: "first_noob", name: "First Noob", description: "Buy your first Noob", condition: .totalNoobLevels(1)),
        AchievementDefinition(id: "ten_levels", name: "Getting Started", description: "Reach 10 total Noob levels", condition: .totalNoobLevels(10)),
        AchievementDefinition(id: "fifty_levels", name: "Noob Army", description: "Reach 50 total Noob levels", condition: .totalNoobLevels(50)),
        AchievementDefinition(id: "two_hundred_levels", name: "Noob Empire", description: "Reach 200 total Noob levels", condition: .totalNoobLevels(200)),
        AchievementDefinition(id: "own_all_noobs", name: "Full Roster", description: "Own every Noob tier", condition: .allNoobsOwned),
        AchievementDefinition(id: "first_thousand", name: "Thousandaire", description: "Earn 1,000 lifetime Oof", condition: .lifetimeEarned(1_000)),
        AchievementDefinition(id: "first_million", name: "Millionaire", description: "Earn 1,000,000 lifetime Oof", condition: .lifetimeEarned(1_000_000)),
        AchievementDefinition(id: "first_billion", name: "Billionaire", description: "Earn 1,000,000,000 lifetime Oof", condition: .lifetimeEarned(1_000_000_000)),
        AchievementDefinition(id: "first_trillion", name: "Trillionaire", description: "Earn 1,000,000,000,000 lifetime Oof", condition: .lifetimeEarned(1_000_000_000_000)),
        AchievementDefinition(id: "first_quadrillion", name: "Quadrillionaire", description: "Earn 1,000,000,000,000,000 lifetime Oof", condition: .lifetimeEarned(1_000_000_000_000_000)),
        AchievementDefinition(id: "max_more_oof", name: "Maxed Out", description: "Max the More Oof upgrade", condition: .upgradeMaxed("more_oof")),
        AchievementDefinition(id: "max_faster_noobs", name: "Speed Demon", description: "Max the Faster Noobs upgrade", condition: .upgradeMaxed("faster_noobs")),
        AchievementDefinition(id: "first_rebirth", name: "Reborn", description: "Rebirth for the first time", condition: .rebirths(1)),
        AchievementDefinition(id: "five_rebirths", name: "Cycle of Life", description: "Rebirth 5 times", condition: .rebirths(5)),
        AchievementDefinition(id: "twenty_five_rebirths", name: "Rebirth Master", description: "Rebirth 25 times", condition: .rebirths(25)),
        AchievementDefinition(id: "hundred_rebirths", name: "Rebirth Legend", description: "Rebirth 100 times", condition: .rebirths(100)),
        AchievementDefinition(id: "max_rebirth_more_oof", name: "Power Overwhelming", description: "Max the rebirth-shop More Oof upgrade", condition: .upgradeMaxed("rebirth_more_oof")),
        AchievementDefinition(id: "redeem_code", name: "Code Breaker", description: "Redeem a code", condition: .codeRedeemed),
        AchievementDefinition(id: "streak_7", name: "Week One", description: "Reach a 7-day login streak", condition: .streakDays(7)),
        AchievementDefinition(id: "streak_30", name: "Dedicated", description: "Reach a 30-day login streak", condition: .streakDays(30)),
        AchievementDefinition(id: "streak_100", name: "Unshakeable", description: "Reach a 100-day login streak", condition: .streakDays(100)),
        AchievementDefinition(id: "explorer", name: "Explorer", description: "Reach Zone 2, The Overworks", condition: .zoneNoobLevels(zoneID: WorldCatalog.zone2ID, total: 1)),
        AchievementDefinition(id: "overworks_master", name: "Overworks Master", description: "Reach 20 total Zone 2 Noob levels", condition: .zoneNoobLevels(zoneID: WorldCatalog.zone2ID, total: 20)),
        AchievementDefinition(id: "ascendant", name: "Ascendant", description: "Reach Zone 3, The Ascension Spire", condition: .zoneNoobLevels(zoneID: WorldCatalog.zone3ID, total: 1)),
        AchievementDefinition(id: "spire_master", name: "Spire Master", description: "Reach 20 total Zone 3 Noob levels", condition: .zoneNoobLevels(zoneID: WorldCatalog.zone3ID, total: 20)),
        AchievementDefinition(id: "rune_collector", name: "Rune Collector", description: "Own every Rune", condition: .allRunesOwned),
        AchievementDefinition(id: "max_rune_oof", name: "Runed Up", description: "Max the Rune of Oof", condition: .upgradeMaxed("rune_oof")),
        AchievementDefinition(id: "menagerie", name: "Menagerie", description: "Unlock every Minion", condition: .allMinionsOwned),
        AchievementDefinition(id: "minion_master", name: "Minion Master", description: "Max the Extra Minion Slots upgrade", condition: .upgradeMaxed("rebirth_minion_slots")),
        AchievementDefinition(id: "insightful", name: "Insightful", description: "Max the Prestige Insight upgrade", condition: .upgradeMaxed("prestige_insight")),
        AchievementDefinition(id: "true_kinship", name: "True Kinship", description: "Max the Rune of Kinship", condition: .upgradeMaxed("rune_kinship")),
        AchievementDefinition(id: "island_native", name: "Island Native", description: "Own every Spawn Island Noob", condition: .allZoneNoobsOwned(zoneID: WorldCatalog.zone1ID)),
        AchievementDefinition(id: "overworks_tycoon", name: "Overworks Tycoon", description: "Own every Overworks Noob", condition: .allZoneNoobsOwned(zoneID: WorldCatalog.zone2ID)),
        AchievementDefinition(id: "spire_sovereign", name: "Spire Sovereign", description: "Own every Ascension Spire Noob", condition: .allZoneNoobsOwned(zoneID: WorldCatalog.zone3ID)),
        AchievementDefinition(id: "well_rested", name: "Well Rested", description: "Max the Extended Rest upgrade", condition: .upgradeMaxed("rebirth_extended_rest"))
    ]

    static func definition(for id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }
}
