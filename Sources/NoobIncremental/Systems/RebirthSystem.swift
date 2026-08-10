import Foundation

/// The reset action: grants Rebirth currency based on current Oof, then wipes Oof, Oof
/// upgrades, and Noob levels. Rebirth currency and Rebirth upgrade levels are untouched —
/// that persistence is the entire point of the system.
enum RebirthSystem {

    /// Requirement escalates per rebirth already performed — reuses the same leveled-cost
    /// curve as everything else in the game (rebirth count standing in for "level").
    static func requirement(rebirthCount: Int) -> Decimal {
        Formulas.levelCost(base: GameBalance.rebirthRequirement, owned: rebirthCount, growthRate: GameBalance.rebirthRequirementGrowthRate)
    }

    static func canRebirth(state: GameState) -> Bool {
        state.currency >= requirement(rebirthCount: state.rebirthCount)
    }

    /// What a rebirth would grant right now — 0 if the requirement isn't met yet.
    /// gain = baseline * sqrt(currency / requirement) * rebirth-upgrade multiplier, so a
    /// rebirth performed right at the requirement nets `baseline`, and pushing further past
    /// it scales the reward — not just the ability to rebirth at all.
    static func availableGain(state: GameState) -> Decimal {
        guard canRebirth(state: state) else { return 0 }
        let req = requirement(rebirthCount: state.rebirthCount)
        let base = GameBalance.rebirthGainBaseline * Formulas.rebirthGain(currency: state.currency, divisor: req)
        return base * RebirthUpgradeStore.rebirthGainMultiplier(state: state)
    }

    /// Returns state unchanged if the requirement isn't met.
    static func performRebirth(state: GameState) -> GameState {
        guard canRebirth(state: state) else { return state }

        var next = state
        next.rebirthCurrency += availableGain(state: state)
        next.rebirthCount += 1
        next.currency = GameBalance.startingCurrency
        next.generators = [:]
        next.upgradeLevels = [:]
        return next
    }
}
