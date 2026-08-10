import Foundation

struct WorldDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let lockedDescription: String
}

enum WorldCatalog {
    static let zone1ID = "zone_1"
    static let zone2ID = "zone_2"

    static let all: [WorldDefinition] = [
        WorldDefinition(id: zone1ID, name: "Spawn Island", lockedDescription: ""),
        WorldDefinition(id: zone2ID, name: "The Overworks", lockedDescription: "Rebirth once to unlock")
    ]

    static func definition(for id: String) -> WorldDefinition? {
        all.first { $0.id == id }
    }
}
