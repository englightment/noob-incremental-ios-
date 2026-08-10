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
    static func levelCost(base: Decimal, owned: Int, growthRate: Double = 1.12) -> Decimal {
        guard owned > 0 else { return base }
        let multiplier = pow(growthRate, Double(owned))
        return base * Decimal(multiplier)
    }

    /// Total cost to buy `quantity` more levels starting from `owned`.
    static func bulkLevelCost(base: Decimal, owned: Int, quantity: Int, growthRate: Double = 1.12) -> Decimal {
        guard quantity > 0 else { return 0 }
        var total: Decimal = 0
        for i in 0..<quantity {
            total += levelCost(base: base, owned: owned + i, growthRate: growthRate)
        }
        return total
    }

    /// How many more levels `availableCurrency` can afford, starting from `owned`. Solves the
    /// geometric-series sum in closed form (cheap even for huge quantities), then nudges the
    /// estimate by a couple of steps to correct for floating-point drift against the exact
    /// Decimal cost — avoids looping level-by-level for uncapped purchases (e.g. Noobs).
    static func maxAffordableLevels(base: Decimal, owned: Int, growthRate: Double = 1.12, availableCurrency: Decimal) -> Int {
        guard availableCurrency > 0, base > 0, growthRate > 1 else { return 0 }
        let firstCost = levelCost(base: base, owned: owned, growthRate: growthRate)
        guard availableCurrency >= firstCost else { return 0 }

        let c = NSDecimalNumber(decimal: availableCurrency).doubleValue
        let f = NSDecimalNumber(decimal: firstCost).doubleValue
        let r = growthRate
        // sum_{i=0}^{k-1} f*r^i <= c  =>  k <= log_r(c*(r-1)/f + 1)
        var k = max(0, Int(floor(log(c * (r - 1) / f + 1) / log(r))))

        while k > 0, bulkLevelCost(base: base, owned: owned, quantity: k, growthRate: growthRate) > availableCurrency {
            k -= 1
        }
        while bulkLevelCost(base: base, owned: owned, quantity: k + 1, growthRate: growthRate) <= availableCurrency {
            k += 1
        }
        return k
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
