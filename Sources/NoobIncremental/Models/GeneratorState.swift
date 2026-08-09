import Foundation

/// Per-save mutable state for one Noob. Static balance data (base cost, base output,
/// unlock condition) lives in GeneratorDefinition. "Level" mirrors the source game's
/// terminology — each purchase levels the Noob up rather than buying a separate copy.
struct GeneratorState: Codable, Equatable {
    var id: String
    var level: Int = 0
    var isUnlocked: Bool = false
}
