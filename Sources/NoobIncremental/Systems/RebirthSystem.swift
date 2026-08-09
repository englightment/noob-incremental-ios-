import Foundation

/// The reset action: grants Rebirth currency based on current Oof, then wipes Oof, Oof
/// upgrades, and Noob levels. Rebirth currency and Rebirth upgrade levels are untouched —
/// that persistence is the entire point of the system.
enum RebirthSystem {

    static func canRebirth(state: GameState) -> Bool {
        state.currency >= GameBalance.rebirthRequirement
    }

    /// What a rebirth would grant right now — 0 if the requirement isn't met yet.
    static func availableGain(state: GameState) -> Decimal {
        guard canRebirth(state: state) else { return 0 }
        let base = Formulas.rebirthGain(currency: state.currency, divisor: GameBalance.rebirthGainDivisor)
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
