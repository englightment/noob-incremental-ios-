import Foundation

/// The single source of truth for a save. Kept as one flat, Codable value type
/// so the whole game can be saved/loaded/offline-fast-forwarded as one blob.
struct GameState: Codable, Equatable {
    // Currency ("Oof")
    var currency: Decimal = GameBalance.startingCurrency
    var lifetimeEarned: Decimal = 0

    // Noobs, keyed by GeneratorDefinition.id
    var generators: [String: GeneratorState] = [:]

    // Global upgrades ("More Oof", "Faster Noobs", ...), keyed by UpgradeDefinition.id -> level purchased
    var upgradeLevels: [String: Int] = [:]

    // Rebirth: a separate currency earned by resetting. Survives resets, along with the
    // levels bought in the Rebirth Upgrades shop below — everything else resets to zero.
    var rebirthCurrency: Decimal = 0
    var rebirthCount: Int = 0
    var rebirthUpgradeLevels: [String: Int] = [:]

    // Rune Shards: a scarce currency earned from Lucky Surges and milestones, spent on
    // permanent Runes. Survives rebirths, same as Rebirth currency.
    var runeShards: Decimal = 0
    var runeLevels: [String: Int] = [:]

    // Pets
    var ownedPets: [String: PetState] = [:]
    var equippedPetIDs: [String] = []

    // Codes
    var redeemedCodes: Set<String> = []

    // Achievements / non-consumable IAP (gamepass-equivalent) ids
    var unlockedAchievements: Set<String> = []
    var purchasedProductIDs: Set<String> = []

    // Lucky Surge: a rare, time-boxed production multiplier.
    var activeBoostMultiplier: Decimal = 1
    var activeBoostExpiresAt: Date?

    // Rewarded-ad boosts: separate from Lucky Surge (different trigger, much longer
    // duration) and from each other (both can be active at once and stack).
    var adBoost2xExpiresAt: Date?
    var adBoost4xExpiresAt: Date?

    // Net-worth milestone tier (power-of-ten index) already celebrated, so the confetti
    // burst only fires once per tier crossed.
    var highestMilestoneCelebrated: Int = 0

    // Quality-of-life settings
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // Daily login streak
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStreakClaimDate: Date?

    // Meta
    var lastSaveTimestamp: Date = Date()
    var totalPlayTime: TimeInterval = 0

    static var newGame: GameState { GameState() }
}
