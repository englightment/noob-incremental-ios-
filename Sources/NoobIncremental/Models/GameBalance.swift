import Foundation

/// Tunable constants that aren't per-generator/per-upgrade formulas (those live in Formulas.swift).
/// Placeholder values — replace with real Roblox-sourced numbers when available.
enum GameBalance {
    /// Oof the player starts with — enough to afford the first Noob immediately,
    /// since there's no tap-to-earn to bootstrap with.
    static let startingCurrency: Decimal = 10

    /// Oof required before the *first* Rebirth. Each subsequent rebirth requires
    /// requirement * rebirthRequirementGrowthRate^rebirthCount — a fixed requirement forever
    /// let players spam cheap rebirths for ~1 currency each, which is what made rebirth
    /// feel linear/pointless. Escalating it makes each rebirth a real step up.
    static let rebirthRequirement: Decimal = 10_000

    /// Growth rate for the escalating requirement above.
    static let rebirthRequirementGrowthRate: Double = 1.6

    /// Flat multiplier on rebirth-currency gain — without it, a rebirth performed right at
    /// the requirement (the common case) nets ~1 currency, which reads as "barely scaling".
    static let rebirthGainBaseline: Decimal = 10

    /// Cost growth rate for rebirth-currency upgrades — steeper than the Oof-currency shop
    /// since each level here is far more powerful (doubling Oof output, etc).
    static let rebirthUpgradeCostGrowthRate: Double = 2.2

    /// Cost growth rate for Rune Shards — Rune Shards trickle in slowly (Lucky Surges,
    /// milestones), so levels need to stay cheap relative to how scarce the currency is.
    static let runeCostGrowthRate: Double = 1.6

    /// Rune Shards granted per Lucky Surge trigger is Int.random(in: this range).
    static let runeShardsPerLuckySurge: ClosedRange<Int> = 1...3

    /// Rune Shards granted each time a new net-worth milestone is celebrated.
    static let runeShardsPerMilestone: Decimal = 1

    /// Baseline seconds-per-Noob-tick before any "Faster Noobs" upgrade is applied.
    static let baseNoobTickSeconds: TimeInterval = 1.0

    /// Floor on how fast "Faster Noobs" can push the effective tick — prevents division blowups.
    static let minimumNoobTickSeconds: TimeInterval = 0.1

    /// Cap on how much elapsed real time counts toward offline progress.
    static let maxOfflineProgressDuration: TimeInterval = 60 * 60 * 8 // 8 hours

    /// How often the live view model refreshes while the app is foregrounded (UI cadence,
    /// unrelated to the in-game Noob production tick above).
    static let uiRefreshInterval: TimeInterval = 0.2

    /// How often GameState autosaves while playing.
    static let autosaveInterval: TimeInterval = 10
}
