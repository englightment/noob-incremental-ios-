import Foundation

struct WorldDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    /// Rebirths required before this world unlocks — 0 for the starting zone.
    let rebirthRequirement: Int
    let lockedDescription: String
}

enum WorldCatalog {
    static let zone1ID = "zone_1"
    static let zone2ID = "zone_2"
    static let zone3ID = "zone_3"

    static let all: [WorldDefinition] = [
        WorldDefinition(id: zone1ID, name: "Spawn Island", rebirthRequirement: 0, lockedDescription: ""),
        WorldDefinition(id: zone2ID, name: "The Overworks", rebirthRequirement: 1, lockedDescription: "Rebirth once to unlock"),
        WorldDefinition(id: zone3ID, name: "The Ascension Spire", rebirthRequirement: 5, lockedDescription: "Rebirth 5 times to unlock")
    ]

    static func definition(for id: String) -> WorldDefinition? {
        all.first { $0.id == id }
    }
}
