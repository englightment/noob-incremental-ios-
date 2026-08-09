import Foundation

/// The single source of truth for a save. Kept as one flat, Codable value type
/// so the whole game can be saved/loaded/offline-fast-forwarded as one blob.
struct GameState: Codable, Equatable {
    // Currency
    var currency: Decimal = 0
    var lifetimeEarned: Decimal = 0

    // Tap
    var tapBaseValue: Decimal = 1
    var tapMultiplier: Decimal = 1

    // Generators, keyed by GeneratorDefinition.id
    var generators: [String: GeneratorState] = [:]

    // Upgrades, storing purchased upgrade ids
    var purchasedUpgrades: Set<String> = []

    // Prestige
    var prestigeCurrency: Decimal = 0
    var prestigeCount: Int = 0

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

    // Meta
    var lastSaveTimestamp: Date = Date()
    var totalPlayTime: TimeInterval = 0

    /// Effective multiplier applied to all currency gains (tap + generators).
    var prestigeMultiplier: Decimal {
        Formulas.prestigeMultiplier(prestigeCurrency: prestigeCurrency)
    }

    static var newGame: GameState { GameState() }
}
