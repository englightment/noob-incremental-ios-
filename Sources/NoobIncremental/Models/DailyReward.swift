import Foundation

/// One entry in the 7-day reward cycle. The cycle repeats indefinitely — streak count keeps
/// climbing (and is what's displayed/protected by loss aversion), but the reward table loops.
struct DailyRewardDefinition {
    let day: Int
    let oof: Decimal
    let rebirthCurrency: Decimal
    let runeShards: Decimal
    let label: String

    init(day: Int, oof: Decimal = 0, rebirthCurrency: Decimal = 0, runeShards: Decimal = 0, label: String) {
        self.day = day
        self.oof = oof
        self.rebirthCurrency = rebirthCurrency
        self.runeShards = runeShards
        self.label = label
    }
}

enum DailyRewardCatalog {
    static let cycle: [DailyRewardDefinition] = [
        DailyRewardDefinition(day: 1, oof: 50, label: "Day 1"),
        DailyRewardDefinition(day: 2, oof: 120, label: "Day 2"),
        DailyRewardDefinition(day: 3, oof: 300, label: "Day 3"),
        DailyRewardDefinition(day: 4, rebirthCurrency: 5, label: "Day 4"),
        DailyRewardDefinition(day: 5, oof: 800, label: "Day 5"),
        DailyRewardDefinition(day: 6, oof: 1_500, label: "Day 6"),
        DailyRewardDefinition(day: 7, rebirthCurrency: 25, label: "Day 7 \u{2014} Big Bonus!"),
        DailyRewardDefinition(day: 8, oof: 3_000, label: "Day 8"),
        DailyRewardDefinition(day: 9, runeShards: 3, label: "Day 9"),
        DailyRewardDefinition(day: 10, oof: 6_000, label: "Day 10"),
        DailyRewardDefinition(day: 11, rebirthCurrency: 40, label: "Day 11"),
        DailyRewardDefinition(day: 12, oof: 10_000, label: "Day 12"),
        DailyRewardDefinition(day: 13, runeShards: 5, label: "Day 13"),
        DailyRewardDefinition(day: 14, oof: 5_000, rebirthCurrency: 60, runeShards: 8, label: "Day 14 \u{2014} Huge Bonus!")
    ]

    static func reward(forStreak streak: Int) -> DailyRewardDefinition {
        let index = (max(streak, 1) - 1) % cycle.count
        return cycle[index]
    }
}
