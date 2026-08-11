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

    /// Guards against ZoneLayoutCatalog silently drifting out of sync with GeneratorCatalog
    /// — e.g. a new Zone 1 generator added without a matching overworld station, which would
    /// make it permanently unreachable in the walkable world despite still existing in the shop.
    func testZone1LayoutHasExactlyOneStationForEveryZone1Generator() {
        assertLayoutHasExactlyOneStationPerGenerator(ZoneLayoutCatalog.zone1, zoneID: WorldCatalog.zone1ID)
    }

    func testZone2LayoutHasExactlyOneStationForEveryZone2Generator() {
        assertLayoutHasExactlyOneStationPerGenerator(ZoneLayoutCatalog.zone2, zoneID: WorldCatalog.zone2ID)
    }

    func testZone3LayoutHasExactlyOneStationForEveryZone3Generator() {
        assertLayoutHasExactlyOneStationPerGenerator(ZoneLayoutCatalog.zone3, zoneID: WorldCatalog.zone3ID)
    }

    func testZone4LayoutHasExactlyOneStationForEveryZone4Generator() {
        assertLayoutHasExactlyOneStationPerGenerator(ZoneLayoutCatalog.zone4, zoneID: WorldCatalog.zone4ID)
    }

    func testZoneLayoutCatalogCoversEveryWorld() {
        for world in WorldCatalog.all {
            XCTAssertNotNil(ZoneLayoutCatalog.layout(for: world.id), "no walkable layout registered for \(world.id)")
        }
    }

    private func assertLayoutHasExactlyOneStationPerGenerator(_ layout: ZoneLayout, zoneID: String, file: StaticString = #filePath, line: UInt = #line) {
        let generatorIDs = Set(GeneratorCatalog.all(inZone: zoneID).map(\.id))
        let stationGeneratorIDs = layout.stations.compactMap { station -> String? in
            guard case .generator(let generatorID) = station.kind else { return nil }
            return generatorID
        }
        XCTAssertEqual(Set(stationGeneratorIDs), generatorIDs, file: file, line: line)
        XCTAssertEqual(stationGeneratorIDs.count, generatorIDs.count, "expected no duplicate generator stations", file: file, line: line)
    }
}
