import Foundation

/// Tunable constants that aren't per-generator/per-upgrade formulas (those live in Formulas.swift).
/// Placeholder values — replace with real Roblox-sourced numbers when available.
enum GameBalance {
    static let defaultZoneID = "zone_spawn"

    /// Cap on how much elapsed real time counts toward offline progress.
    static let maxOfflineProgressDuration: TimeInterval = 60 * 60 * 8 // 8 hours

    /// How often the live game loop ticks while the app is foregrounded.
    static let tickInterval: TimeInterval = 0.2

    /// How often GameState autosaves while playing.
    static let autosaveInterval: TimeInterval = 10
}
