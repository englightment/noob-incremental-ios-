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

    static let zone2 = ZoneLayout(
        zoneID: WorldCatalog.zone2ID,
        canvasSize: CGSize(width: 500, height: 760),
        // A bit further from station_zone1_gate (250, 700) than zone1's spawn is from its own
        // gate, so arriving here doesn't immediately show the "return to Spawn Island" prompt
        // before the player has moved at all (700-600=100 > the gate's 60pt interactionRadius).
        spawnPoint: CGPoint(x: 250, y: 600),
        stations: [
            WorldStationDefinition(
                id: "station_portal_noob", kind: .generator(generatorID: "portal_noob"),
                name: "Portal Noob", icon: "circle.hexagongrid.fill",
                position: CGPoint(x: 120, y: 560), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_cosmic_noob", kind: .generator(generatorID: "cosmic_noob"),
                name: "Cosmic Noob", icon: "sparkles",
                position: CGPoint(x: 380, y: 560), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_void_noob", kind: .generator(generatorID: "void_noob"),
                name: "Void Noob", icon: "circle.dotted",
                position: CGPoint(x: 120, y: 400), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_nebula_noob", kind: .generator(generatorID: "nebula_noob"),
                name: "Nebula Noob", icon: "cloud.fill",
                position: CGPoint(x: 380, y: 400), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_singularity_noob", kind: .generator(generatorID: "singularity_noob"),
                name: "Singularity Noob", icon: "smallcircle.filled.circle.fill",
                position: CGPoint(x: 250, y: 240), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_minion_den", kind: .minionDen,
                name: "Minion Den", icon: "pawprint.fill",
                position: CGPoint(x: 60, y: 220), interactionRadius: 55
            ),
            WorldStationDefinition(
                id: "station_zone1_gate", kind: .zoneTransition(targetZoneID: WorldCatalog.zone1ID),
                name: "Spawn Island", icon: "house.fill",
                position: CGPoint(x: 250, y: 700), interactionRadius: 60
            ),
            WorldStationDefinition(
                id: "station_zone3_gate", kind: .zoneTransition(targetZoneID: WorldCatalog.zone3ID),
                name: "The Ascension Spire", icon: "mountain.2.fill",
                position: CGPoint(x: 250, y: 60), interactionRadius: 60
            )
        ]
    )

    static func layout(for zoneID: String) -> ZoneLayout? {
        switch zoneID {
        case WorldCatalog.zone1ID: return zone1
        case WorldCatalog.zone2ID: return zone2
        default: return nil
        }
    }
}
