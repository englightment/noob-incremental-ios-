import Foundation

/// Pure balance math. Nothing here touches GameState directly — everything is
/// (inputs) -> output, so values can be tuned/tested without touching the game loop.
///
/// Growth-rate placeholders below are standard idle-game defaults; replace with the
/// real Roblox formulas once known.
enum Formulas {

    // MARK: - Leveled cost (used by generators and both upgrade shops)

    /// Cost of the next level's purchase, given how many levels are already owned.
    /// cost = base * growthRate^owned
    static func levelCost(base: Decimal, owned: Int, growthRate: Double = 1.15) -> Decimal {
        guard owned > 0 else { return base }
        let multiplier = pow(growthRate, Double(owned))
        return base * Decimal(multiplier)
    }

    /// Total cost to buy `quantity` more levels starting from `owned`.
    static func bulkLevelCost(base: Decimal, owned: Int, quantity: Int, growthRate: Double = 1.15) -> Decimal {
        guard quantity > 0 else { return 0 }
        var total: Decimal = 0
        for i in 0..<quantity {
            total += levelCost(base: base, owned: owned + i, growthRate: growthRate)
        }
        return total
    }

    // MARK: - Generators

    /// Passive output per second for one generator type, before summing across types.
    static func generatorOutput(baseOutput: Decimal, owned: Int, outputMultiplier: Decimal) -> Decimal {
        guard owned > 0 else { return 0 }
        return baseOutput * Decimal(owned) * outputMultiplier
    }

    // MARK: - Rebirth

    /// Rebirth currency granted for resetting at the given current-Oof total.
    /// gain = sqrt(currency / divisor), floored at 0.
    static func rebirthGain(currency: Decimal, divisor: Decimal = 10_000) -> Decimal {
        guard currency > 0, divisor > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: currency / divisor).doubleValue
        guard ratio > 0 else { return 0 }
        return Decimal(sqrt(ratio))
    }
}
