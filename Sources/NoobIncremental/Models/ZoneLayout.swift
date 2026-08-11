import CoreGraphics

/// A zone's walkable overworld layout: how big its canvas is, where the player spawns, and
/// which stations sit where. Coordinates are in that zone's own logical canvas space.
struct ZoneLayout {
    let zoneID: String
    let canvasSize: CGSize
    let spawnPoint: CGPoint
    let stations: [WorldStationDefinition]
}

enum ZoneLayoutCatalog {
    // Kept close to one screen in size deliberately — see the approved overworld plan's
    // camera-risk notes. A typical portrait iPhone viewport is roughly 390x844 logical
    // points minus safe areas, so this canvas only ever needs a small amount of camera
    // scroll at the extreme top/bottom edges.
    static let zone1 = ZoneLayout(
        zoneID: WorldCatalog.zone1ID,
        canvasSize: CGSize(width: 500, height: 760),
        spawnPoint: CGPoint(x: 250, y: 650),
        stations: [
            WorldStationDefinition(
                id: "station_starter_noob", kind: .generator(generatorID: "starter_noob"),
                name: "Starter Noob", icon: "house.fill",
                position: CGPoint(x: 120, y: 560), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_farmer_noob", kind: .generator(generatorID: "farmer_noob"),
                name: "Farmer Noob", icon: "leaf.fill",
                position: CGPoint(x: 380, y: 560), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_builder_noob", kind: .generator(generatorID: "builder_noob"),
                name: "Builder Noob", icon: "hammer.fill",
                position: CGPoint(x: 120, y: 400), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_miner_noob", kind: .generator(generatorID: "miner_noob"),
                name: "Miner Noob", icon: "cube.fill",
                position: CGPoint(x: 380, y: 400), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_tower_noob", kind: .generator(generatorID: "tower_noob"),
                name: "Tower Noob", icon: "building.2.fill",
                position: CGPoint(x: 250, y: 240), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_rebirth_altar", kind: .rebirthAltar,
                name: "Rebirth Altar", icon: "arrow.triangle.2.circlepath",
                position: CGPoint(x: 250, y: 460), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_upgrade_workshop", kind: .upgradeWorkshop,
                name: "Upgrade Workshop", icon: "arrow.up.circle.fill",
                position: CGPoint(x: 60, y: 220), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_rune_shrine", kind: .runeShrine,
                name: "Rune Shrine", icon: "seal.fill",
                position: CGPoint(x: 440, y: 220), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_zone2_gate", kind: .zoneTransition(targetZoneID: WorldCatalog.zone2ID),
                name: "The Overworks", icon: "moon.stars.fill",
                position: CGPoint(x: 250, y: 60), interactionRadius: 60
            )
        ]
    )

    static func layout(for zoneID: String) -> ZoneLayout? {
        zoneID == WorldCatalog.zone1ID ? zone1 : nil
    }
}
