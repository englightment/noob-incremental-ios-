import Foundation

/// A minion is unlocked automatically by hitting a specific achievement (no separate currency
/// sink) and grants a flat production bonus while equipped. Only `MinionSystem.maxEquipped(state:)`
/// can be active at once, so which ones to run is a real choice, not just a checklist.
struct MinionDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let unlockAchievementID: String
    let unlockHint: String
    let outputBonus: Decimal
}

enum MinionCatalog {
    static let all: [MinionDefinition] = [
        MinionDefinition(
            id: "minion_whiskers",
            name: "Whiskers",
            icon: "hare.fill",
            unlockAchievementID: "first_noob",
            unlockHint: "Buy your first Noob",
            outputBonus: 0.03
        ),
        MinionDefinition(
            id: "minion_sparky",
            name: "Sparky",
            icon: "bolt.fill",
            unlockAchievementID: "first_million",
            unlockHint: "Earn 1,000,000 lifetime Oof",
            outputBonus: 0.05
        ),
        MinionDefinition(
            id: "minion_ashe",
            name: "Ashe",
            icon: "flame.fill",
            unlockAchievementID: "first_rebirth",
            unlockHint: "Rebirth for the first time",
            outputBonus: 0.06
        ),
        MinionDefinition(
            id: "minion_portal_pup",
            name: "Portal Pup",
            icon: "pawprint.fill",
            unlockAchievementID: "explorer",
            unlockHint: "Reach Zone 2, The Overworks",
            outputBonus: 0.08
        ),
        MinionDefinition(
            id: "minion_prism",
            name: "Prism",
            icon: "sparkles",
            unlockAchievementID: "rune_collector",
            unlockHint: "Own every Rune",
            outputBonus: 0.10
        ),
        MinionDefinition(
            id: "minion_eternal",
            name: "Eternal",
            icon: "infinity",
            unlockAchievementID: "hundred_rebirths",
            unlockHint: "Rebirth 100 times",
            outputBonus: 0.20
        ),
        MinionDefinition(
            id: "minion_seraph",
            name: "Seraph",
            icon: "star.fill",
            unlockAchievementID: "ascendant",
            unlockHint: "Reach Zone 3, The Ascension Spire",
            outputBonus: 0.12
        ),
        MinionDefinition(
            id: "minion_celestine",
            name: "Celestine",
            icon: "crown.fill",
            unlockAchievementID: "spire_master",
            unlockHint: "Reach 20 total Zone 3 Noob levels",
            outputBonus: 0.15
        ),
        MinionDefinition(
            id: "minion_riftling",
            name: "Riftling",
            icon: "atom",
            unlockAchievementID: "voidbound",
            unlockHint: "Reach Zone 4, The Void Expanse",
            outputBonus: 0.16
        )
    ]

    static func definition(for id: String) -> MinionDefinition? {
        all.first { $0.id == id }
    }
}
