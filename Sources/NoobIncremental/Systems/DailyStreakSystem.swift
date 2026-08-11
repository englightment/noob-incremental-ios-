import Foundation

/// Daily login streak — classic loss-aversion retention hook (a la Duolingo): missing a day
/// resets the streak, which makes protecting it feel like defending something already earned
/// rather than chasing something new. `now`/`calendar` are injectable for testing.
enum DailyStreakSystem {

    static func canClaim(state: GameState, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let last = state.lastStreakClaimDate else { return true }
        return !calendar.isDate(last, inSameDayAs: now)
    }

    /// The streak value a claim right now would produce — continues the streak if the last
    /// claim was yesterday, otherwise resets to 1. Meaningless if `canClaim` is false.
    static func pendingStreakValue(state: GameState, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let last = state.lastStreakClaimDate else { return 1 }
        let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day ?? Int.max
        return daysSince == 1 ? state.currentStreak + 1 : 1
    }

    /// Returns nil (no-op) if a claim already happened today.
    static func claim(state: GameState, now: Date = Date(), calendar: Calendar = .current) -> (state: GameState, reward: DailyRewardDefinition)? {
        guard canClaim(state: state, now: now, calendar: calendar) else { return nil }

        let newStreak = pendingStreakValue(state: state, now: now, calendar: calendar)
        let reward = DailyRewardCatalog.reward(forStreak: newStreak)

        var next = state
        next.currentStreak = newStreak
        next.longestStreak = max(next.longestStreak, newStreak)
        next.lastStreakClaimDate = now
        next.currency += reward.oof
        next.rebirthCurrency += reward.rebirthCurrency
        next.runeShards += reward.runeShards
        return (next, reward)
    }
}
