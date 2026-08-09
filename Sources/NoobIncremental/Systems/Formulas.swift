import Foundation

/// Pure balance math. Nothing here touches GameState directly — everything is
/// (inputs) -> output, so values can be tuned/tested without touching the game loop.
///
/// Growth-rate placeholders below are standard idle-game defaults; replace with the
/// real Roblox formulas once known.
enum Formulas {

    // MARK: - Leveled cost (used by both generators and global upgrades)

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

    /// Passive output per tick for one generator type.
    static func generatorOutput(baseOutput: Decimal, owned: Int, outputMultiplier: Decimal, prestigeMultiplier: Decimal) -> Decimal {
        guard owned > 0 else { return 0 }
        return baseOutput * Decimal(owned) * outputMultiplier * prestigeMultiplier
    }

    // MARK: - Prestige

    /// Prestige currency granted for resetting at the given lifetime-earned total.
    /// gain = sqrt(lifetimeEarned / threshold), floored at 0.
    static func prestigeGain(lifetimeEarned: Decimal, threshold: Decimal = 1_000_000) -> Decimal {
        guard lifetimeEarned > 0, threshold > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: lifetimeEarned / threshold).doubleValue
        guard ratio > 0 else { return 0 }
        return Decimal(sqrt(ratio))
    }

    /// Permanent multiplier applied to all currency gains, derived from banked prestige currency.
    /// multiplier = 1 + log10(prestigeCurrency + 1) * 0.1
    static func prestigeMultiplier(prestigeCurrency: Decimal) -> Decimal {
        guard prestigeCurrency > 0 else { return 1 }
        let value = NSDecimalNumber(decimal: prestigeCurrency).doubleValue
        let bonus = log10(value + 1) * 0.1
        return 1 + Decimal(bonus)
    }
}
