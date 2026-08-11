import Foundation

struct WorldDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    /// Rebirths required before this world unlocks — 0 for the starting zone.
    let rebirthRequirement: Int
    let lockedDescription: String
    /// SF Symbol name for this world's tab. Tint color is a View-layer concern (see
    /// ContentView's worldTint(for:)) so this model stays free of SwiftUI.
    let icon: String
}

enum WorldCatalog {
    static let zone1ID = "zone_1"
    static let zone2ID = "zone_2"
    static let zone3ID = "zone_3"

    static let all: [WorldDefinition] = [
        WorldDefinition(id: zone1ID, name: "Spawn Island", rebirthRequirement: 0, lockedDescription: "", icon: "house.fill"),
        WorldDefinition(id: zone2ID, name: "The Overworks", rebirthRequirement: 1, lockedDescription: "Rebirth once to unlock", icon: "moon.stars.fill"),
        WorldDefinition(id: zone3ID, name: "The Ascension Spire", rebirthRequirement: 5, lockedDescription: "Rebirth 5 times to unlock", icon: "mountain.2.fill")
    ]

    static func definition(for id: String) -> WorldDefinition? {
        all.first { $0.id == id }
    }
}
