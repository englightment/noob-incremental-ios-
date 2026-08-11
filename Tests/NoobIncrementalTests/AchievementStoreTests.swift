import XCTest
@testable import NoobIncremental

final class AchievementStoreTests: XCTestCase {

    private let earnedAchievement = AchievementDefinition(id: "test_earned", name: "Test Earned", description: "", condition: .lifetimeEarned(1_000))
    private let rebirthAchievement = AchievementDefinition(id: "test_rebirths", name: "Test Rebirths", description: "", condition: .rebirths(2))

    func testConditionMetForLifetimeEarned() {
        var state = GameState.newGame
        state.lifetimeEarned = 999
        XCTAssertFalse(AchievementStore.conditionMet(earnedAchievement, state: state))

        state.lifetimeEarned = 1_000
        XCTAssertTrue(AchievementStore.conditionMet(earnedAchievement, state: state))
    }

    func testConditionMetForRebirths() {
        var state = GameState.newGame
        state.rebirthCount = 1
        XCTAssertFalse(AchievementStore.conditionMet(rebirthAchievement, state: state))

        state.rebirthCount = 2
        XCTAssertTrue(AchievementStore.conditionMet(rebirthAchievement, state: state))
    }

    func testConditionMetForStreakDays() {
        let definition = AchievementDefinition(id: "test_streak", name: "Test Streak", description: "", condition: .streakDays(7))
        var state = GameState.newGame
        state.longestStreak = 6
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state))

        state.longestStreak = 7
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testTotalNoobLevelsConditionSumsAcrossGeneratorTypes() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob"),
              let farmer = GeneratorCatalog.definition(for: "farmer_noob") else {
            return XCTFail("expected generators missing from catalog")
        }
        let definition = AchievementDefinition(id: "test_total", name: "Test", description: "", condition: .totalNoobLevels(3))
        var state = GameState.newGame
        state.currency = 1_000_000
        state = GeneratorStore.buy(starter, state: state)
        state = GeneratorStore.buy(farmer, state: state)
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state)) // only 2 total levels so far

        state = GeneratorStore.buy(starter, state: state)
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state)) // now 3
    }

    func testAllNoobsOwnedConditionRequiresEveryTier() {
        let definition = AchievementDefinition(id: "test_all", name: "Test", description: "", condition: .allNoobsOwned)
        var state = GameState.newGame
        state.currency = 10_000_000
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state))

        // Must cover the priciest Zone 4 Noob (currently up to ~945 quadrillion) — this
        // budget is intentionally generous (a full quintillion headroom) rather than tightly
        // pinned to today's catalog costs, so it doesn't need touching every time balance
        // changes. It has already had to move once (from 1 quadrillion) when Zone 4 shipped.
        state.currency = 1_000_000_000_000_000_000_000
        for generator in GeneratorCatalog.all {
            state = GeneratorStore.buy(generator, state: state)
        }
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testIsUnlockedReflectsUnlockedSet() {
        var state = GameState.newGame
        XCTAssertFalse(AchievementStore.isUnlocked(earnedAchievement, state: state))

        state.unlockedAchievements.insert(earnedAchievement.id)
        XCTAssertTrue(AchievementStore.isUnlocked(earnedAchievement, state: state))
    }

    func testNewlyUnlockableExcludesAlreadyUnlocked() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000
        state.unlockedAchievements.insert("first_noob") // an id that happens to also be met but pre-unlocked

        let newly = AchievementStore.newlyUnlockable(state: state)
        XCTAssertFalse(newly.contains { $0.id == "first_noob" })
    }

    func testUnlockNewlyMetRecordsAndReturnsThem() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000_000_000_000 // trips multiple lifetimeEarned achievements at once

        let (newState, unlocked) = AchievementStore.unlockNewlyMet(state: state)

        XCTAssertGreaterThan(unlocked.count, 1)
        for definition in unlocked {
            XCTAssertTrue(newState.unlockedAchievements.contains(definition.id))
        }
    }

    func testUnlockNewlyMetIsIdempotent() {
        var state = GameState.newGame
        state.lifetimeEarned = 1_000
        let (afterFirst, _) = AchievementStore.unlockNewlyMet(state: state)

        let (afterSecond, unlockedAgain) = AchievementStore.unlockNewlyMet(state: afterFirst)

        XCTAssertTrue(unlockedAgain.isEmpty)
        XCTAssertEqual(afterSecond, afterFirst)
    }

    func testOutputMultiplierIsOneWithNoAchievements() {
        let state = GameState.newGame
        XCTAssertEqual(AchievementStore.outputMultiplier(state: state), 1)
    }

    func testOutputMultiplierStacksPerUnlockedAchievement() {
        var state = GameState.newGame
        state.unlockedAchievements = ["a", "b", "c"]
        let expected = 1 + Decimal(3) * AchievementStore.outputMultiplierPerAchievement
        XCTAssertEqual(AchievementStore.outputMultiplier(state: state), expected)
    }

    func testZone2NoobLevelsConditionOnlyCountsZone2() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob"),
              let portal = GeneratorCatalog.definition(for: "portal_noob") else {
            return XCTFail("expected generators missing from catalog")
        }
        let definition = AchievementDefinition(id: "test_zone2", name: "Test", description: "", condition: .zoneNoobLevels(zoneID: WorldCatalog.zone2ID, total: 1))
        var state = GameState.newGame
        state.currency = 10_000_000_000
        state = GeneratorStore.buy(starter, state: state)
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state), "Zone 1 levels shouldn't count toward a Zone 2 achievement")

        state = GeneratorStore.buy(portal, state: state)
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testAllZoneNoobsOwnedRequiresEveryNoobInThatZoneOnly() {
        let zone2Generators = GeneratorCatalog.all(inZone: WorldCatalog.zone2ID)
        guard zone2Generators.count > 1 else {
            return XCTFail("expected multiple Zone 2 generators")
        }
        let definition = AchievementDefinition(id: "test_zone2_complete", name: "Test", description: "", condition: .allZoneNoobsOwned(zoneID: WorldCatalog.zone2ID))
        var state = GameState.newGame
        state.currency = 1_000_000_000_000

        for generator in zone2Generators.dropLast() {
            state = GeneratorStore.buy(generator, state: state)
        }
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state), "shouldn't unlock until every Zone 2 Noob is owned")

        state = GeneratorStore.buy(zone2Generators.last!, state: state)
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testVoidSovereignRequiresEveryZone4NoobOwned() {
        guard let voidSovereign = AchievementCatalog.definition(for: "void_sovereign") else {
            return XCTFail("void_sovereign missing from catalog")
        }
        let zone4Generators = GeneratorCatalog.all(inZone: WorldCatalog.zone4ID)
        guard zone4Generators.count > 1 else {
            return XCTFail("expected multiple Zone 4 generators")
        }
        var state = GameState.newGame
        state.currency = 1_000_000_000_000_000_000_000

        for generator in zone4Generators.dropLast() {
            state = GeneratorStore.buy(generator, state: state)
        }
        XCTAssertFalse(AchievementStore.conditionMet(voidSovereign, state: state))

        state = GeneratorStore.buy(zone4Generators.last!, state: state)
        XCTAssertTrue(AchievementStore.conditionMet(voidSovereign, state: state))
    }

    func testAllRunesOwnedConditionRequiresEveryRune() {
        let definition = AchievementDefinition(id: "test_all_runes", name: "Test", description: "", condition: .allRunesOwned)
        var state = GameState.newGame
        state.runeShards = 1_000_000
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state))

        for rune in RuneCatalog.all {
            state = RuneStore.buyOne(rune, state: state)
        }
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testUpgradeMaxedConditionChecksRuneCatalogToo() {
        guard let runeOof = RuneCatalog.definition(for: "rune_oof") else {
            return XCTFail("rune_oof missing from catalog")
        }
        let definition = AchievementDefinition(id: "test_max_rune", name: "Test", description: "", condition: .upgradeMaxed("rune_oof"))
        var state = GameState.newGame
        state.runeShards = 1_000_000_000
        XCTAssertFalse(AchievementStore.conditionMet(definition, state: state))

        state = RuneStore.buyMax(runeOof, state: state)
        XCTAssertTrue(AchievementStore.conditionMet(definition, state: state))
    }

    func testEveryUpgradeMaxedAchievementReferencesARealUpgrade() {
        for achievement in AchievementCatalog.all {
            guard case .upgradeMaxed(let id) = achievement.condition else { continue }
            let existsSomewhere = UpgradeCatalog.definition(for: id) != nil
                || RebirthUpgradeCatalog.definition(for: id) != nil
                || RuneCatalog.definition(for: id) != nil
            XCTAssertTrue(existsSomewhere, "\(achievement.id) references unknown upgrade \(id)")
        }
    }

    func testProgressForLifetimeEarned() {
        var state = GameState.newGame
        state.lifetimeEarned = 400

        let progress = AchievementStore.progress(earnedAchievement, state: state)

        XCTAssertEqual(progress?.current, 400)
        XCTAssertEqual(progress?.target, 1_000)
    }

    func testProgressForRebirths() {
        var state = GameState.newGame
        state.rebirthCount = 1

        let progress = AchievementStore.progress(rebirthAchievement, state: state)

        XCTAssertEqual(progress?.current, 1)
        XCTAssertEqual(progress?.target, 2)
    }

    func testProgressForAllNoobsOwnedCountsOwnedTiers() {
        guard let starter = GeneratorCatalog.definition(for: "starter_noob") else {
            return XCTFail("starter_noob missing from catalog")
        }
        let definition = AchievementDefinition(id: "test_progress_all_noobs", name: "Test", description: "", condition: .allNoobsOwned)
        var state = GameState.newGame
        state.currency = 1_000_000

        let before = AchievementStore.progress(definition, state: state)
        XCTAssertEqual(before?.current, 0)
        XCTAssertEqual(before?.target, Decimal(GeneratorCatalog.all.count))

        state = GeneratorStore.buy(starter, state: state)
        let after = AchievementStore.progress(definition, state: state)
        XCTAssertEqual(after?.current, 1)
    }

    func testProgressForUpgradeMaxedReadsCurrentLevel() {
        guard let moreOof = UpgradeCatalog.definition(for: "more_oof") else {
            return XCTFail("more_oof missing from catalog")
        }
        let definition = AchievementDefinition(id: "test_progress_upgrade", name: "Test", description: "", condition: .upgradeMaxed("more_oof"))
        var state = GameState.newGame
        state.currency = 1_000_000
        state = UpgradeStore.buyOne(moreOof, state: state)

        let progress = AchievementStore.progress(definition, state: state)

        XCTAssertEqual(progress?.current, 1)
        XCTAssertEqual(progress?.target, Decimal(moreOof.maxLevel))
    }

    func testProgressIsNilForCodeRedeemed() {
        let definition = AchievementDefinition(id: "test_progress_code", name: "Test", description: "", condition: .codeRedeemed)
        XCTAssertNil(AchievementStore.progress(definition, state: .newGame))
    }

    func testProgressIsNilForProductOwned() {
        let definition = AchievementDefinition(id: "test_progress_product", name: "Test", description: "", condition: .productOwned(IAPProduct.supporterPack.rawValue))
        XCTAssertNil(AchievementStore.progress(definition, state: .newGame))
    }

    func testPatronConditionMetOnceSupporterPackOwned() {
        guard let patron = AchievementCatalog.definition(for: "patron") else {
            return XCTFail("patron missing from catalog")
        }
        XCTAssertFalse(AchievementStore.conditionMet(patron, state: .newGame))

        let state = IAPSystem.applyPurchase(.supporterPack, to: .newGame)
        XCTAssertTrue(AchievementStore.conditionMet(patron, state: state))
    }

    func testProgressFractionIsZeroWhenNoProgress() {
        XCTAssertEqual(AchievementStore.progressFraction(earnedAchievement, state: .newGame), 0)
    }

    func testProgressFractionReflectsHalfway() {
        var state = GameState.newGame
        state.lifetimeEarned = 500

        XCTAssertEqual(AchievementStore.progressFraction(earnedAchievement, state: state), 0.5, accuracy: 0.0001)
    }

    func testProgressFractionNeverExceedsOne() {
        var state = GameState.newGame
        state.lifetimeEarned = 50_000 // way past the 1,000 target

        XCTAssertEqual(AchievementStore.progressFraction(earnedAchievement, state: state), 1.0, accuracy: 0.0001)
    }

    func testProgressFractionIsZeroForCodeRedeemed() {
        let definition = AchievementDefinition(id: "test_fraction_code", name: "Test", description: "", condition: .codeRedeemed)
        XCTAssertEqual(AchievementStore.progressFraction(definition, state: .newGame), 0)
    }

    func testSortedForDisplayPutsUnlockedAchievementsFirst() {
        var state = GameState.newGame
        state.unlockedAchievements = ["first_noob"]

        let sorted = AchievementStore.sortedForDisplay(state: state)

        XCTAssertEqual(sorted.first?.id, "first_noob")
    }

    func testSortedForDisplayOrdersLockedAchievementsByProximityToCompletion() {
        var state = GameState.newGame
        state.lifetimeEarned = 999_000 // very close to first_quadrillion? no — close to first_million (1,000,000)

        let sorted = AchievementStore.sortedForDisplay(state: state)
        let lockedOnly = sorted.filter { !AchievementStore.isUnlocked($0, state: state) }
        let indexOfMillionaire = lockedOnly.firstIndex { $0.id == "first_million" }
        let indexOfQuadrillionaire = lockedOnly.firstIndex { $0.id == "first_quadrillion" }

        guard let millionaireIndex = indexOfMillionaire, let quadrillionaireIndex = indexOfQuadrillionaire else {
            return XCTFail("expected achievements missing from catalog")
        }
        XCTAssertLessThan(millionaireIndex, quadrillionaireIndex, "being 99.9% of the way to Millionaire should sort before a barely-started Quadrillionaire")
    }

    func testSortedForDisplayIncludesEveryAchievementExactlyOnce() {
        let sorted = AchievementStore.sortedForDisplay(state: .newGame)
        XCTAssertEqual(Set(sorted.map(\.id)).count, AchievementCatalog.all.count)
        XCTAssertEqual(sorted.count, AchievementCatalog.all.count)
    }
}
