import Foundation

/// Cookie-Clicker-style building milestones: crossing a level threshold on a Noob doubles
/// that specific Noob's own output (stacking with every other multiplier), independent of
/// how many other Noob types are owned. Same thresholds apply to every generator so the
/// player learns the pattern once instead of memorizing per-Noob numbers.
enum GeneratorMilestoneSystem {

    static let thresholds = [25, 50, 100, 250, 500, 1_000]

    /// This generator's own output multiplier from milestones already crossed at `level`.
    static func multiplier(level: Int) -> Decimal {
        let crossed = thresholds.count { level >= $0 }
        guard crossed > 0 else { return 1 }
        return Decimal(pow(2.0, Double(crossed)))
    }

    /// The next not-yet-crossed threshold, or nil once every milestone has been hit.
    static func nextThreshold(level: Int) -> Int? {
        thresholds.first { level < $0 }
    }

    /// How many thresholds fall strictly between `previousLevel` and `newLevel` — used to
    /// detect "did this purchase just cross a milestone" for celebratory feedback.
    static func crossedCount(from previousLevel: Int, to newLevel: Int) -> Int {
        thresholds.count { $0 > previousLevel && $0 <= newLevel }
    }
}
