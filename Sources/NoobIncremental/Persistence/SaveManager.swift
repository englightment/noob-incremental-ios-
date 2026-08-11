import Foundation

/// Loads/saves the single GameState blob as JSON in the app's Documents directory.
final class SaveManager {
    static let shared = SaveManager()

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    private static func defaultFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("save.json")
    }

    func load() -> GameState {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? decoder.decode(GameState.self, from: data) else {
            return .newGame
        }
        return state
    }

    func save(_ state: GameState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Encodes the save as a compact backup code (base64 JSON) for manual export — a safety
    /// net specifically for this project's testing setup, since Sideloadly's free-Apple-ID
    /// signing expires every 7 days and reinstalling to re-sign can wipe local app data.
    func exportCode(_ state: GameState) -> String? {
        try? encoder.encode(state).base64EncodedString()
    }

    /// Decodes a backup code produced by `exportCode(_:)`. Doesn't touch the on-disk save —
    /// callers decide whether/when to commit the restored state via `save(_:)`.
    func decodeImportCode(_ code: String) -> GameState? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: trimmed) else { return nil }
        return try? decoder.decode(GameState.self, from: data)
    }
}
