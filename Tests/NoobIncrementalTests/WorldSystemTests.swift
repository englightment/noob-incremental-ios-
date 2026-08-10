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

    func testZone1AndZone2PartitionAllGenerators() {
        let zone1Count = GeneratorCatalog.all(inZone: WorldCatalog.zone1ID).count
        let zone2Count = GeneratorCatalog.all(inZone: WorldCatalog.zone2ID).count
        XCTAssertEqual(zone1Count + zone2Count, GeneratorCatalog.all.count)
        XCTAssertGreaterThan(zone1Count, 0)
        XCTAssertGreaterThan(zone2Count, 0)
    }
}
