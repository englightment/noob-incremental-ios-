import Foundation

enum RedeemResult: Equatable {
    case success(RedeemCodeDefinition)
    case alreadyRedeemed
    case invalid
}

enum RedeemCodeStore {
    static func redeem(_ rawCode: String, state: GameState) -> (state: GameState, result: RedeemResult) {
        guard let definition = RedeemCodeCatalog.definition(for: rawCode) else {
            return (state, .invalid)
        }
        guard !state.redeemedCodes.contains(definition.code) else {
            return (state, .alreadyRedeemed)
        }

        var next = state
        next.redeemedCodes.insert(definition.code)
        next.currency += definition.rewardOof
        next.rebirthCurrency += definition.rewardRebirth
        return (next, .success(definition))
    }
}
