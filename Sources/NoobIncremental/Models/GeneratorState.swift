import Foundation

/// Per-save mutable state for one owned generator. Static balance data
/// (base cost, base output, unlock condition) lives in GeneratorDefinition.
struct GeneratorState: Codable, Equatable {
    var id: String
    var owned: Int = 0
    var isUnlocked: Bool = false
}
