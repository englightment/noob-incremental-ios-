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

        // Must cover the priciest Zone 3 Noob (currently up to low trillions), not just
        // Zone 1/2 — this budget is intentionally generous rather than tightly pinned to
        // today's catalog costs, so it doesn't need touching every time balance changes.
        state.currency = 10_000_000_000_000
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
}
