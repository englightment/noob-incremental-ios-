import XCTest
@testable import NoobIncremental

final class GameStateDecodingTests: XCTestCase {

    private func makeCoders() -> (JSONEncoder, JSONDecoder) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (encoder, decoder)
    }

    func testRoundTripPreservesAllFields() throws {
        let (encoder, decoder) = makeCoders()
        var state = GameState.newGame
        state.currency = 12_345
        state.lifetimeEarned = 999_999
        state.generators = ["starter_noob": GeneratorState(id: "starter_noob", level: 3)]
        state.rebirthCurrency = 42
        state.rebirthCount = 2
        state.runeShards = 7
        state.ownedMinions = ["minion_whiskers": MinionState(id: "minion_whiskers", isUnlocked: true)]
        state.equippedMinionIDs = ["minion_whiskers"]
        state.redeemedCodes = ["WELCOME"]
        state.unlockedAchievements = ["first_noob"]
        state.currentStreak = 5
        state.soundEnabled = false

        let data = try encoder.encode(state)
        let decoded = try decoder.decode(GameState.self, from: data)

        XCTAssertEqual(decoded, state)
    }

    func testDecodingSucceedsWithMissingKeysAndFillsInDefaults() throws {
        // Simulates loading a save written before a field existed — decoding an *empty*
        // object must succeed and every field must fall back to its default, rather than
        // the whole decode throwing (which is what SaveManager.load() falls back to
        // GameState.newGame for, silently wiping the player's progress).
        let (_, decoder) = makeCoders()
        let emptyObjectData = Data("{}".utf8)

        let decoded = try decoder.decode(GameState.self, from: emptyObjectData)

        XCTAssertEqual(decoded, GameState.newGame)
    }

    func testDecodingWithOnlySomeKeysPresentKeepsThoseValuesAndDefaultsTheRest() throws {
        let (encoder, decoder) = makeCoders()
        var full = GameState.newGame
        full.currency = 500
        full.rebirthCount = 3

        // Round-trip through the real encoder, then strip every key except two, rather than
        // hand-writing raw JSON — that would require guessing Decimal's exact wire format.
        let fullData = try encoder.encode(full)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: fullData) as? [String: Any])
        let partialJSON = json.filter { ["currency", "rebirthCount"].contains($0.key) }
        let partialData = try JSONSerialization.data(withJSONObject: partialJSON)

        let decoded = try decoder.decode(GameState.self, from: partialData)

        XCTAssertEqual(decoded.currency, 500)
        XCTAssertEqual(decoded.rebirthCount, 3)
        // Everything else should still fall back to its default.
        XCTAssertEqual(decoded.lifetimeEarned, 0)
        XCTAssertEqual(decoded.rebirthCurrency, 0)
        XCTAssertTrue(decoded.generators.isEmpty)
        XCTAssertTrue(decoded.soundEnabled)
    }

    func testSaveManagerFallsBackGracefullyOnGenuinelyCorruptData() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("corrupt-save-\(UUID().uuidString).json")
        try? Data("not even json".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let manager = SaveManager(fileURL: tempURL)
        let state = manager.load()

        XCTAssertEqual(state, GameState.newGame)
    }

    func testSaveManagerLoadsASaveMissingNewerFieldsWithoutLosingOlderData() throws {
        // A "save from the past": has the original core fields but is missing everything
        // added since (Minions, ad boosts, streak fields, etc). Built by encoding a real
        // GameState and stripping the newer keys, rather than hand-writing JSON, so this
        // doesn't depend on guessing Decimal/Date's exact wire format.
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("old-save-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let (encoder, _) = makeCoders()
        var full = GameState.newGame
        full.currency = 88_888
        full.lifetimeEarned = 1_000_000
        full.generators = ["starter_noob": GeneratorState(id: "starter_noob", level: 10)]
        full.upgradeLevels = ["more_oof": 2]

        let fullData = try encoder.encode(full)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: fullData) as? [String: Any])
        let oldFieldNames: Set<String> = ["currency", "lifetimeEarned", "generators", "upgradeLevels"]
        let oldJSON = json.filter { oldFieldNames.contains($0.key) }
        let oldSaveData = try JSONSerialization.data(withJSONObject: oldJSON)
        try oldSaveData.write(to: tempURL)

        let manager = SaveManager(fileURL: tempURL)
        let state = manager.load()

        XCTAssertEqual(state.currency, 88_888, "old data should survive, not fall back to newGame")
        XCTAssertEqual(state.lifetimeEarned, 1_000_000)
        XCTAssertEqual(GeneratorStore.level(GeneratorCatalog.definition(for: "starter_noob")!, state: state), 10)
        XCTAssertEqual(state.upgradeLevels["more_oof"], 2)
        // Newer fields not present in the old save should just be defaults.
        XCTAssertTrue(state.ownedMinions.isEmpty)
        XCTAssertNil(state.adBoost2xExpiresAt)
    }
}
