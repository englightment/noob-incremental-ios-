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

    // Zones
    var unlockedZones: Set<String> = [GameBalance.defaultZoneID]
    var currentZone: String = GameBalance.defaultZoneID

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

    // Net-worth milestone tier (power-of-ten index) already celebrated, so the confetti
    // burst only fires once per tier crossed.
    var highestMilestoneCelebrated: Int = 0

    // Quality-of-life settings
    var autoBuyEnabled: Bool = false
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // Meta
    var lastSaveTimestamp: Date = Date()
    var totalPlayTime: TimeInterval = 0

    static var newGame: GameState { GameState() }
}
