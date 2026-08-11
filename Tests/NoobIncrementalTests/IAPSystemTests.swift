import XCTest
@testable import NoobIncremental

final class IAPSystemTests: XCTestCase {

    func testProductIsNotOwnedByDefault() {
        let state = GameState.newGame
        XCTAssertFalse(IAPSystem.isOwned(.supporterPack, state: state))
    }

    func testApplyingNonConsumablePurchaseRecordsOwnership() {
        let state = GameState.newGame
        let next = IAPSystem.applyPurchase(.supporterPack, to: state)
        XCTAssertTrue(IAPSystem.isOwned(.supporterPack, state: next))
        XCTAssertTrue(next.purchasedProductIDs.contains(IAPProduct.supporterPack.rawValue))
    }

    func testApplyingSameNonConsumablePurchaseTwiceIsIdempotent() {
        let state = GameState.newGame
        let once = IAPSystem.applyPurchase(.supporterPack, to: state)
        let twice = IAPSystem.applyPurchase(.supporterPack, to: once)
        XCTAssertEqual(once.purchasedProductIDs, twice.purchasedProductIDs)
    }

    func testApplyingConsumablePurchaseGrantsRuneShardsWithoutRecordingOwnership() {
        let state = GameState.newGame
        let next = IAPSystem.applyPurchase(.runeShardPackSmall, to: state)
        XCTAssertEqual(next.runeShards, state.runeShards + IAPProduct.runeShardPackSmall.runeShardGrant)
        XCTAssertFalse(next.purchasedProductIDs.contains(IAPProduct.runeShardPackSmall.rawValue))
    }

    func testApplyingConsumablePurchaseRepeatedlyStacksTheGrant() {
        let state = GameState.newGame
        let once = IAPSystem.applyPurchase(.runeShardPackLarge, to: state)
        let twice = IAPSystem.applyPurchase(.runeShardPackLarge, to: once)
        XCTAssertEqual(twice.runeShards, IAPProduct.runeShardPackLarge.runeShardGrant * 2)
    }

    func testOutputMultiplierIsOneWithoutSupporterPack() {
        let state = GameState.newGame
        XCTAssertEqual(IAPSystem.outputMultiplier(state: state), 1)
    }

    func testOutputMultiplierAppliesSupporterBonusOnceOwned() {
        let state = IAPSystem.applyPurchase(.supporterPack, to: .newGame)
        XCTAssertEqual(IAPSystem.outputMultiplier(state: state), IAPSystem.supporterOutputMultiplier)
    }
}
