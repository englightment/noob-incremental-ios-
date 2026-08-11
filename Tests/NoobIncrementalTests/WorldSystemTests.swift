import XCTest
@testable import NoobIncremental

final class WorldSystemTests: XCTestCase {

    func testZone1IsAlwaysUnlocked() {
        guard let zone1 = WorldCatalog.definition(for: WorldCatalog.zone1ID) else {
            return XCTFail("zone_1 missing from catalog")
        }
        let state = GameState.newGame
        XCTAssertTrue(WorldSystem.isUnlocked(zone1, state: state))
    }

    func testZone2IsLockedBeforeFirstRebirth() {
        guard let zone2 = WorldCatalog.definition(for: WorldCatalog.zone2ID) else {
            return XCTFail("zone_2 missing from catalog")
        }
        let state = GameState.newGame
        XCTAssertFalse(WorldSystem.isUnlocked(zone2, state: state))
    }

    func testZone2UnlocksAfterFirstRebirth() {
        guard let zone2 = WorldCatalog.definition(for: WorldCatalog.zone2ID) else {
            return XCTFail("zone_2 missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCount = 1
        XCTAssertTrue(WorldSystem.isUnlocked(zone2, state: state))
    }

    func testEveryGeneratorBelongsToAKnownWorld() {
        let knownZoneIDs = Set(WorldCatalog.all.map(\.id))
        for generator in GeneratorCatalog.all {
            XCTAssertTrue(knownZoneIDs.contains(generator.zoneID), "\(generator.id) references unknown zone \(generator.zoneID)")
        }
    }

    func testAllZonesPartitionAllGenerators() {
        let counts = WorldCatalog.all.map { GeneratorCatalog.all(inZone: $0.id).count }
        XCTAssertEqual(counts.reduce(0, +), GeneratorCatalog.all.count)
        for count in counts {
            XCTAssertGreaterThan(count, 0)
        }
    }

    func testZone3IsLockedBeforeFiveRebirths() {
        guard let zone3 = WorldCatalog.definition(for: WorldCatalog.zone3ID) else {
            return XCTFail("zone_3 missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCount = 4
        XCTAssertFalse(WorldSystem.isUnlocked(zone3, state: state))
    }

    func testZone3UnlocksAtFiveRebirths() {
        guard let zone3 = WorldCatalog.definition(for: WorldCatalog.zone3ID) else {
            return XCTFail("zone_3 missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCount = 5
        XCTAssertTrue(WorldSystem.isUnlocked(zone3, state: state))
    }

    func testZone4IsLockedBeforeFifteenRebirths() {
        guard let zone4 = WorldCatalog.definition(for: WorldCatalog.zone4ID) else {
            return XCTFail("zone_4 missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCount = 14
        XCTAssertFalse(WorldSystem.isUnlocked(zone4, state: state))
    }

    func testZone4UnlocksAtFifteenRebirths() {
        guard let zone4 = WorldCatalog.definition(for: WorldCatalog.zone4ID) else {
            return XCTFail("zone_4 missing from catalog")
        }
        var state = GameState.newGame
        state.rebirthCount = 15
        XCTAssertTrue(WorldSystem.isUnlocked(zone4, state: state))
    }
}
