import XCTest
@testable import NoobIncremental

final class RebirthSystemTests: XCTestCase {

    func testCannotRebirthBelowRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement - 1
        XCTAssertFalse(RebirthSystem.canRebirth(state: state))
    }

    func testCanRebirthAtRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        XCTAssertTrue(RebirthSystem.canRebirth(state: state))
    }

    func testAvailableGainIsZeroBelowRequirement() {
        var state = GameState.newGame
        state.currency = 5
        XCTAssertEqual(RebirthSystem.availableGain(state: state), 0)
    }

    func testAvailableGainIsPositiveAtRequirement() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        XCTAssertGreaterThan(RebirthSystem.availableGain(state: state), 0)
    }

    func testPerformRebirthBelowRequirementLeavesStateUnchanged() {
        var state = GameState.newGame
        state.currency = 5

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(result, state)
    }

    func testPerformRebirthGrantsRebirthCurrencyAndIncrementsCount() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertGreaterThan(result.rebirthCurrency, 0)
        XCTAssertEqual(result.rebirthCount, 1)
    }

    func testPerformRebirthResetsOofOofUpgradesAndNoobs() {
        guard let noob = GeneratorCatalog.definition(for: "starter_noob"),
              let moreOof = UpgradeCatalog.definition(for: "more_oof") else {
            return XCTFail("expected catalog entries missing")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement + 1_000_000
        state = GeneratorStore.buy(noob, state: state)
        state = UpgradeStore.buyOne(moreOof, state: state)

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(result.currency, GameBalance.startingCurrency)
        XCTAssertTrue(result.generators.isEmpty)
        XCTAssertTrue(result.upgradeLevels.isEmpty)
    }

    func testPerformRebirthPreservesExistingRebirthCurrencyAndUpgrades() {
        guard let rebirthMoreOof = RebirthUpgradeCatalog.definition(for: "rebirth_more_oof") else {
            return XCTFail("rebirth_more_oof missing from catalog")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        state.rebirthCurrency = 20_000
        state = RebirthUpgradeStore.buyOne(rebirthMoreOof, state: state)
        let rebirthUpgradeLevelBefore = RebirthUpgradeStore.level(rebirthMoreOof, state: state)
        XCTAssertEqual(rebirthUpgradeLevelBefore, 1, "precondition: purchase should have succeeded")

        let result = RebirthSystem.performRebirth(state: state)

        XCTAssertEqual(RebirthUpgradeStore.level(rebirthMoreOof, state: result), rebirthUpgradeLevelBefore)
        XCTAssertGreaterThan(result.rebirthCurrency, 0) // leftover balance plus this rebirth's gain
    }

    // MARK: - Escalating requirement (the actual bug fix)

    func testRequirementAtZeroRebirthsEqualsBaseRequirement() {
        XCTAssertEqual(RebirthSystem.requirement(rebirthCount: 0), GameBalance.rebirthRequirement)
    }

    func testRequirementEscalatesWithEachRebirth() {
        var previous = RebirthSystem.requirement(rebirthCount: 0)
        for count in 1...10 {
            let current = RebirthSystem.requirement(rebirthCount: count)
            XCTAssertGreaterThan(current, previous, "requirement should strictly increase at rebirthCount=\(count)")
            previous = current
        }
    }

    func testPerformRebirthRaisesTheRequirementForTheNextOne() {
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement

        let afterFirst = RebirthSystem.performRebirth(state: state)

        XCTAssertGreaterThan(RebirthSystem.requirement(rebirthCount: afterFirst.rebirthCount), GameBalance.rebirthRequirement)
        XCTAssertFalse(RebirthSystem.canRebirth(state: afterFirst), "resets to starting currency, well below the new higher requirement")
    }

    func testGainAtExactlyRequirementEqualsBaseline() {
        var state = GameState.newGame
        state.currency = RebirthSystem.requirement(rebirthCount: 0)

        let gain = NSDecimalNumber(decimal: RebirthSystem.availableGain(state: state)).doubleValue
        let baseline = NSDecimalNumber(decimal: GameBalance.rebirthGainBaseline).doubleValue

        XCTAssertEqual(gain, baseline, accuracy: 0.0001, "a rebirth right at the requirement should net the baseline, not ~1")
    }

    func testGainScalesWithOvershootPastRequirement() {
        let requirement = RebirthSystem.requirement(rebirthCount: 0)
        var atRequirement = GameState.newGame
        atRequirement.currency = requirement
        var wayOver = GameState.newGame
        wayOver.currency = requirement * 100

        let gainAtRequirement = RebirthSystem.availableGain(state: atRequirement)
        let gainWayOver = RebirthSystem.availableGain(state: wayOver)

        XCTAssertGreaterThan(gainWayOver, gainAtRequirement * 5, "pushing 100x past the requirement should be worth meaningfully more than the minimum")
    }

    func testPrestigeInsightIncreasesAvailableGain() {
        guard UpgradeCatalog.definition(for: "prestige_insight") != nil else {
            return XCTFail("prestige_insight missing from catalog")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        let gainWithoutUpgrade = RebirthSystem.availableGain(state: state)

        // Set the level directly rather than buying — Prestige Insight is bought with Oof,
        // the same currency the gain formula reads, so spending it would confound the
        // comparison by also shrinking the base gain.
        state.upgradeLevels["prestige_insight"] = 1
        let gainWithUpgrade = RebirthSystem.availableGain(state: state)

        XCTAssertGreaterThan(gainWithUpgrade, gainWithoutUpgrade)
    }

    func testRuneOfRebirthIncreasesAvailableGain() {
        guard let runeRebirth = RuneCatalog.definition(for: "rune_rebirth") else {
            return XCTFail("rune_rebirth missing from catalog")
        }
        var state = GameState.newGame
        state.currency = GameBalance.rebirthRequirement
        let gainWithoutRune = RebirthSystem.availableGain(state: state)

        state.runeShards = 1_000_000
        state = RuneStore.buyOne(runeRebirth, state: state)
        let gainWithRune = RebirthSystem.availableGain(state: state)

        XCTAssertGreaterThan(gainWithRune, gainWithoutRune)
    }
}
