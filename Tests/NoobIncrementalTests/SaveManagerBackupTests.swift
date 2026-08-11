import XCTest
@testable import NoobIncremental

final class SaveManagerBackupTests: XCTestCase {

    func testExportThenImportRoundTripsTheSave() {
        let manager = SaveManager(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused-\(UUID().uuidString).json"))
        var state = GameState.newGame
        state.currency = 54_321
        state.rebirthCount = 4
        state.unlockedAchievements = ["first_noob", "first_rebirth"]

        guard let code = manager.exportCode(state) else {
            return XCTFail("exportCode returned nil")
        }
        let imported = manager.decodeImportCode(code)

        XCTAssertEqual(imported, state)
    }

    func testImportRejectsGarbageInput() {
        let manager = SaveManager(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused-\(UUID().uuidString).json"))
        XCTAssertNil(manager.decodeImportCode("not a real backup code"))
    }

    func testImportRejectsValidBase64ThatIsntAGameState() {
        let manager = SaveManager(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused-\(UUID().uuidString).json"))
        let unrelatedData = Data("hello world".utf8).base64EncodedString()
        XCTAssertNil(manager.decodeImportCode(unrelatedData))
    }

    func testImportTrimsWhitespaceAroundThePastedCode() {
        let manager = SaveManager(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused-\(UUID().uuidString).json"))
        var state = GameState.newGame
        state.currency = 777

        guard let code = manager.exportCode(state) else {
            return XCTFail("exportCode returned nil")
        }
        let padded = "  \n\(code)\n  "

        XCTAssertEqual(manager.decodeImportCode(padded), state)
    }

    func testImportedSaveCanBeWrittenAndReloaded() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("import-target-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let manager = SaveManager(fileURL: tempURL)

        var toImport = GameState.newGame
        toImport.currency = 999
        guard let code = manager.exportCode(toImport) else {
            return XCTFail("exportCode returned nil")
        }
        guard let decoded = manager.decodeImportCode(code) else {
            return XCTFail("decodeImportCode returned nil")
        }
        manager.save(decoded)

        XCTAssertEqual(manager.load().currency, 999)
    }
}
