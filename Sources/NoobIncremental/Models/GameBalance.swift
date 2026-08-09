import Foundation

/// Tunable constants that aren't per-generator/per-upgrade formulas (those live in Formulas.swift).
/// Placeholder values — replace with real Roblox-sourced numbers when available.
enum GameBalance {
    static let defaultZoneID = "zone_spawn"

    /// Oof the player starts with — enough to afford the first Noob immediately,
    /// since there's no tap-to-earn to bootstrap with.
    static let startingCurrency: Decimal = 10

    /// Lifetime Oof earned required to reach the next prestige.
    static let prestigeThreshold: Decimal = 5_000_000_000_000 // 5T, matches "0/5T Oofs"

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
