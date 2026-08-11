import Foundation

/// `code` is always stored uppercase — matching is case-insensitive.
struct RedeemCodeDefinition: Equatable {
    let code: String
    let rewardOof: Decimal
    let rewardRebirth: Decimal
    let description: String
}

enum RedeemCodeCatalog {
    static let all: [RedeemCodeDefinition] = [
        RedeemCodeDefinition(code: "WELCOME", rewardOof: 100, rewardRebirth: 0, description: "Welcome gift"),
        RedeemCodeDefinition(code: "LAUNCH", rewardOof: 500, rewardRebirth: 0, description: "Launch bonus"),
        RedeemCodeDefinition(code: "NOOBS", rewardOof: 0, rewardRebirth: 5, description: "Free Rebirth currency"),
        RedeemCodeDefinition(code: "ASCEND", rewardOof: 0, rewardRebirth: 15, description: "Zone 3 celebration bonus"),
        RedeemCodeDefinition(code: "THANKYOU", rewardOof: 2_500, rewardRebirth: 0, description: "Thanks for playing")
    ]

    static func definition(for rawCode: String) -> RedeemCodeDefinition? {
        let normalized = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return all.first { $0.code == normalized }
    }
}
