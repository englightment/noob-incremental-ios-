import Foundation

/// "Lucky Surge" — a rare, time-boxed production multiplier. The random roll and scheduling
/// live in GameViewModel (impure by nature); this just answers "is a boost active right now,
/// and by how much" from state, so GameLoop can stay pure and testable.
enum BoostSystem {

    static func isActive(state: GameState, now: Date = Date()) -> Bool {
        guard let expiresAt = state.activeBoostExpiresAt else { return false }
        return now < expiresAt
    }

    static func activeMultiplier(state: GameState, now: Date = Date()) -> Decimal {
        isActive(state: state, now: now) ? state.activeBoostMultiplier : 1
    }

    static func remainingSeconds(state: GameState, now: Date = Date()) -> TimeInterval {
        guard let expiresAt = state.activeBoostExpiresAt, expiresAt > now else { return 0 }
        return expiresAt.timeIntervalSince(now)
    }

    static func start(state: GameState, multiplier: Decimal, duration: TimeInterval, now: Date = Date()) -> GameState {
        var next = state
        next.activeBoostMultiplier = multiplier
        next.activeBoostExpiresAt = now.addingTimeInterval(duration)
        return next
    }
}
