import Foundation

/// Per-save mutable state for one owned pet.
struct PetState: Codable, Equatable {
    var id: String
    var level: Int = 1
    var isUnlocked: Bool = false
}
