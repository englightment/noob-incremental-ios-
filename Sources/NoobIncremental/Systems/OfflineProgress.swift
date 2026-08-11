import Foundation

/// Result of fast-forwarding a save through the time it was closed.
struct OfflineProgressResult: Equatable {
    let state: GameState
    let elapsedDuration: TimeInterval
    let currencyEarned: Decimal
}

enum OfflineProgress {

    /// Computes elapsed time since `state.lastSaveTimestamp`, caps it at
    /// `GameBalance.maxOfflineProgressDuration` plus whatever the "Extended Rest" rebirth
    /// upgrade has added, and applies one large GameLoop.tick step.
    static func apply(to state: GameState, now: Date = Date()) -> OfflineProgressResult {
        let cap = GameBalance.maxOfflineProgressDuration + RebirthUpgradeStore.offlineCapBonus(state: state)
        let rawElapsed = now.timeIntervalSince(state.lastSaveTimestamp)
        let cappedElapsed = max(0, min(rawElapsed, cap))

        let before = state.currency
        var next = GameLoop.tick(state, elapsed: cappedElapsed)
        next.lastSaveTimestamp = now

        return OfflineProgressResult(
            state: next,
            elapsedDuration: cappedElapsed,
            currencyEarned: next.currency - before
        )
    }
}
