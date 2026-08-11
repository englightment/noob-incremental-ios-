import CoreGraphics

/// What happens when the player walks up to a station in the 2D overworld.
enum WorldStationKind: Equatable {
    case generator(generatorID: String)
    case zoneTransition(targetZoneID: String)
    // .rebirthAltar, .runeShrine, .minionDen intentionally not added yet — later phases.
}

/// A fixed, interactive point of interest placed in a zone's walkable world (see
/// ZoneLayoutCatalog). Position is in that zone's own logical canvas coordinate space, not
/// screen points — OverworldView is responsible for translating canvas space to what's
/// actually visible via its camera offset.
struct WorldStationDefinition: Identifiable, Equatable {
    let id: String
    let kind: WorldStationKind
    let name: String
    let icon: String
    let position: CGPoint
    let interactionRadius: CGFloat
}
