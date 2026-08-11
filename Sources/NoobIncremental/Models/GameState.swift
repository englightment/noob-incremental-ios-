import Foundation

/// The single source of truth for a save. Kept as one flat, Codable value type
/// so the whole game can be saved/loaded/offline-fast-forwarded as one blob.
///
/// Decoding is hand-written (rather than relying on the synthesized all-or-nothing decoder)
/// so that adding a new field here — which has happened many times as the game grew — never
/// makes older save files unreadable. A save written before a field existed just falls back
/// to that field's default instead of failing the whole decode and wiping the player's save.
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

    // Minions
    var ownedMinions: [String: MinionState] = [:]
    var equippedMinionIDs: [String] = []

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
    var offlineReminderEnabled: Bool = true

    // Daily login streak
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStreakClaimDate: Date?

    // Meta
    var lastSaveTimestamp: Date = Date()
    var totalPlayTime: TimeInterval = 0

    // First-launch onboarding — see OnboardingSystem. Backfilled to true on load for any
    // save that already has real progress, so this can never resurface for existing players.
    var hasSeenOnboarding: Bool = false

    static var newGame: GameState { GameState() }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case currency, lifetimeEarned, generators, upgradeLevels
        case rebirthCurrency, rebirthCount, rebirthUpgradeLevels
        case runeShards, runeLevels
        case ownedMinions, equippedMinionIDs
        case redeemedCodes
        case unlockedAchievements, purchasedProductIDs
        case activeBoostMultiplier, activeBoostExpiresAt
        case adBoost2xExpiresAt, adBoost4xExpiresAt
        case highestMilestoneCelebrated
        case soundEnabled, hapticsEnabled, offlineReminderEnabled
        case currentStreak, longestStreak, lastStreakClaimDate
        case lastSaveTimestamp, totalPlayTime
        case hasSeenOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currency = try container.decodeIfPresent(Decimal.self, forKey: .currency) ?? GameBalance.startingCurrency
        lifetimeEarned = try container.decodeIfPresent(Decimal.self, forKey: .lifetimeEarned) ?? 0
        generators = try container.decodeIfPresent([String: GeneratorState].self, forKey: .generators) ?? [:]
        upgradeLevels = try container.decodeIfPresent([String: Int].self, forKey: .upgradeLevels) ?? [:]
        rebirthCurrency = try container.decodeIfPresent(Decimal.self, forKey: .rebirthCurrency) ?? 0
        rebirthCount = try container.decodeIfPresent(Int.self, forKey: .rebirthCount) ?? 0
        rebirthUpgradeLevels = try container.decodeIfPresent([String: Int].self, forKey: .rebirthUpgradeLevels) ?? [:]
        runeShards = try container.decodeIfPresent(Decimal.self, forKey: .runeShards) ?? 0
        runeLevels = try container.decodeIfPresent([String: Int].self, forKey: .runeLevels) ?? [:]
        ownedMinions = try container.decodeIfPresent([String: MinionState].self, forKey: .ownedMinions) ?? [:]
        equippedMinionIDs = try container.decodeIfPresent([String].self, forKey: .equippedMinionIDs) ?? []
        redeemedCodes = try container.decodeIfPresent(Set<String>.self, forKey: .redeemedCodes) ?? []
        unlockedAchievements = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedAchievements) ?? []
        purchasedProductIDs = try container.decodeIfPresent(Set<String>.self, forKey: .purchasedProductIDs) ?? []
        activeBoostMultiplier = try container.decodeIfPresent(Decimal.self, forKey: .activeBoostMultiplier) ?? 1
        activeBoostExpiresAt = try container.decodeIfPresent(Date.self, forKey: .activeBoostExpiresAt)
        adBoost2xExpiresAt = try container.decodeIfPresent(Date.self, forKey: .adBoost2xExpiresAt)
        adBoost4xExpiresAt = try container.decodeIfPresent(Date.self, forKey: .adBoost4xExpiresAt)
        highestMilestoneCelebrated = try container.decodeIfPresent(Int.self, forKey: .highestMilestoneCelebrated) ?? 0
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        offlineReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .offlineReminderEnabled) ?? true
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastStreakClaimDate = try container.decodeIfPresent(Date.self, forKey: .lastStreakClaimDate)
        lastSaveTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastSaveTimestamp) ?? Date()
        totalPlayTime = try container.decodeIfPresent(TimeInterval.self, forKey: .totalPlayTime) ?? 0
        hasSeenOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currency, forKey: .currency)
        try container.encode(lifetimeEarned, forKey: .lifetimeEarned)
        try container.encode(generators, forKey: .generators)
        try container.encode(upgradeLevels, forKey: .upgradeLevels)
        try container.encode(rebirthCurrency, forKey: .rebirthCurrency)
        try container.encode(rebirthCount, forKey: .rebirthCount)
        try container.encode(rebirthUpgradeLevels, forKey: .rebirthUpgradeLevels)
        try container.encode(runeShards, forKey: .runeShards)
        try container.encode(runeLevels, forKey: .runeLevels)
        try container.encode(ownedMinions, forKey: .ownedMinions)
        try container.encode(equippedMinionIDs, forKey: .equippedMinionIDs)
        try container.encode(redeemedCodes, forKey: .redeemedCodes)
        try container.encode(unlockedAchievements, forKey: .unlockedAchievements)
        try container.encode(purchasedProductIDs, forKey: .purchasedProductIDs)
        try container.encode(activeBoostMultiplier, forKey: .activeBoostMultiplier)
        try container.encodeIfPresent(activeBoostExpiresAt, forKey: .activeBoostExpiresAt)
        try container.encodeIfPresent(adBoost2xExpiresAt, forKey: .adBoost2xExpiresAt)
        try container.encodeIfPresent(adBoost4xExpiresAt, forKey: .adBoost4xExpiresAt)
        try container.encode(highestMilestoneCelebrated, forKey: .highestMilestoneCelebrated)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(offlineReminderEnabled, forKey: .offlineReminderEnabled)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encodeIfPresent(lastStreakClaimDate, forKey: .lastStreakClaimDate)
        try container.encode(lastSaveTimestamp, forKey: .lastSaveTimestamp)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(hasSeenOnboarding, forKey: .hasSeenOnboarding)
    }
}
