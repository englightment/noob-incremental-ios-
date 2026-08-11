import XCTest
@testable import NoobIncremental

final class PlayerMovementSystemTests: XCTestCase {

    private let canvas = CGSize(width: 500, height: 760)

    // MARK: - move / clamp

    func testMoveWithZeroDirectionDoesNotMovePlayer() {
        let start = CGPoint(x: 100, y: 100)
        let result = PlayerMovementSystem.move(from: start, direction: .zero, speed: 200, deltaTime: 1, canvasSize: canvas)
        XCTAssertEqual(result, start)
    }

    func testMoveClampsAtCanvasLowerBound() {
        let start = CGPoint(x: 5, y: 5)
        let result = PlayerMovementSystem.move(from: start, direction: CGVector(dx: -1, dy: -1), speed: 200, deltaTime: 1, canvasSize: canvas)
        XCTAssertEqual(result.x, 0)
        XCTAssertEqual(result.y, 0)
    }

    func testMoveClampsAtCanvasUpperBound() {
        let start = CGPoint(x: canvas.width - 5, y: canvas.height - 5)
        let result = PlayerMovementSystem.move(from: start, direction: CGVector(dx: 1, dy: 1), speed: 200, deltaTime: 1, canvasSize: canvas)
        XCTAssertEqual(result.x, canvas.width)
        XCTAssertEqual(result.y, canvas.height)
    }

    func testDiagonalMovementIsNotFasterThanCardinalMovement() {
        let start = CGPoint(x: 250, y: 380)
        let cardinal = PlayerMovementSystem.clampMagnitude(CGVector(dx: 1, dy: 0), to: 1)
        let diagonal = PlayerMovementSystem.clampMagnitude(CGVector(dx: 1, dy: 1), to: 1)

        let cardinalResult = PlayerMovementSystem.move(from: start, direction: cardinal, speed: 100, deltaTime: 1, canvasSize: canvas)
        let diagonalResult = PlayerMovementSystem.move(from: start, direction: diagonal, speed: 100, deltaTime: 1, canvasSize: canvas)

        let cardinalDistance = PlayerMovementSystem.distance(start, cardinalResult)
        let diagonalDistance = PlayerMovementSystem.distance(start, diagonalResult)
        XCTAssertEqual(cardinalDistance, diagonalDistance, accuracy: 0.001)
    }

    func testClampMagnitudeLeavesVectorsAlreadyWithinBoundsUnchanged() {
        let vector = CGVector(dx: 0.3, dy: 0.4) // magnitude 0.5
        let clamped = PlayerMovementSystem.clampMagnitude(vector, to: 1)
        XCTAssertEqual(clamped.dx, vector.dx, accuracy: 0.0001)
        XCTAssertEqual(clamped.dy, vector.dy, accuracy: 0.0001)
    }

    // MARK: - nearestStation / isInRange

    private func station(_ id: String, x: CGFloat, y: CGFloat, radius: CGFloat = 50) -> WorldStationDefinition {
        WorldStationDefinition(id: id, kind: .generator(generatorID: id), name: id, icon: "circle", position: CGPoint(x: x, y: y), interactionRadius: radius)
    }

    func testNearestStationReturnsNilForEmptyList() {
        XCTAssertNil(PlayerMovementSystem.nearestStation(to: CGPoint(x: 0, y: 0), among: []))
    }

    func testNearestStationPicksClosestOfSeveral() {
        let near = station("near", x: 110, y: 100)
        let far = station("far", x: 400, y: 400)
        let nearest = PlayerMovementSystem.nearestStation(to: CGPoint(x: 100, y: 100), among: [far, near])
        XCTAssertEqual(nearest?.id, "near")
    }

    func testIsInRangeAtExactRadiusBoundaryIsTrue() {
        let s = station("s", x: 100, y: 100, radius: 50)
        XCTAssertTrue(PlayerMovementSystem.isInRange(CGPoint(x: 150, y: 100), of: s))
    }

    func testIsInRangeJustOutsideRadiusIsFalse() {
        let s = station("s", x: 100, y: 100, radius: 50)
        XCTAssertFalse(PlayerMovementSystem.isInRange(CGPoint(x: 150.5, y: 100), of: s))
    }

    // MARK: - cameraOffset

    func testCameraOffsetIsZeroWhenPlayerNearOrigin() {
        let offset = PlayerMovementSystem.cameraOffset(playerPosition: CGPoint(x: 0, y: 0), canvasSize: canvas, viewportSize: CGSize(width: 390, height: 700))
        XCTAssertEqual(offset.x, 0)
        XCTAssertEqual(offset.y, 0)
    }

    func testCameraOffsetClampsToMaxWhenPlayerNearFarEdge() {
        let viewport = CGSize(width: 390, height: 700)
        let offset = PlayerMovementSystem.cameraOffset(playerPosition: CGPoint(x: canvas.width, y: canvas.height), canvasSize: canvas, viewportSize: viewport)
        XCTAssertEqual(offset.x, canvas.width - viewport.width)
        XCTAssertEqual(offset.y, canvas.height - viewport.height)
    }

    func testCameraOffsetTracksPlayerInDeadZone() {
        let viewport = CGSize(width: 200, height: 300)
        let player = CGPoint(x: 250, y: 380) // roughly centered in `canvas`
        let offset = PlayerMovementSystem.cameraOffset(playerPosition: player, canvasSize: canvas, viewportSize: viewport)
        XCTAssertEqual(offset.x, player.x - viewport.width / 2, accuracy: 0.001)
        XCTAssertEqual(offset.y, player.y - viewport.height / 2, accuracy: 0.001)
    }

    func testCameraOffsetNeverNegativeWhenCanvasSmallerThanViewport() {
        let tinyCanvas = CGSize(width: 100, height: 100)
        let bigViewport = CGSize(width: 390, height: 700)
        let offset = PlayerMovementSystem.cameraOffset(playerPosition: CGPoint(x: 50, y: 50), canvasSize: tinyCanvas, viewportSize: bigViewport)
        XCTAssertEqual(offset.x, 0)
        XCTAssertEqual(offset.y, 0)
    }
}
