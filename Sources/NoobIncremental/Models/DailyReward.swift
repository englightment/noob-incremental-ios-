import Foundation

/// One entry in the 7-day reward cycle. The cycle repeats indefinitely — streak count keeps
/// climbing (and is what's displayed/protected by loss aversion), but the reward table loops.
struct DailyRewardDefinition {
    let day: Int
    let oof: Decimal
    let rebirthCurrency: Decimal
    let label: String
}

enum DailyRewardCatalog {
    static let cycle: [DailyRewardDefinition] = [
        DailyRewardDefinition(day: 1, oof: 50, rebirthCurrency: 0, label: "Day 1"),
        DailyRewardDefinition(day: 2, oof: 120, rebirthCurrency: 0, label: "Day 2"),
        DailyRewardDefinition(day: 3, oof: 300, rebirthCurrency: 0, label: "Day 3"),
        DailyRewardDefinition(day: 4, oof: 0, rebirthCurrency: 5, label: "Day 4"),
        DailyRewardDefinition(day: 5, oof: 800, rebirthCurrency: 0, label: "Day 5"),
        DailyRewardDefinition(day: 6, oof: 1_500, rebirthCurrency: 0, label: "Day 6"),
        DailyRewardDefinition(day: 7, oof: 0, rebirthCurrency: 25, label: "Day 7 \u{2014} Big Bonus!")
    ]

    static func reward(forStreak streak: Int) -> DailyRewardDefinition {
        let index = (max(streak, 1) - 1) % cycle.count
        return cycle[index]
    }
}
