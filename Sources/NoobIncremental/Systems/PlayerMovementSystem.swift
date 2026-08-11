import CoreGraphics
import Foundation

/// Pure 2D movement/camera math for the overworld — no SwiftUI import, so it's directly
/// unit-testable the same way every other System in this codebase is. OverworldView owns
/// the actual per-frame loop (a TimelineView) and just calls into these functions each tick.
enum PlayerMovementSystem {

    /// Clamps a joystick's raw drag vector to unit magnitude before it's used as a movement
    /// direction. Skipping this is the classic "diagonal movement is faster than cardinal"
    /// bug — an unclamped (dx: 1, dy: 1) has magnitude sqrt(2), not 1.
    static func clampMagnitude(_ vector: CGVector, to maxMagnitude: CGFloat) -> CGVector {
        let magnitude = (vector.dx * vector.dx + vector.dy * vector.dy).squareRoot()
        guard magnitude > maxMagnitude, magnitude > 0 else { return vector }
        let scale = maxMagnitude / magnitude
        return CGVector(dx: vector.dx * scale, dy: vector.dy * scale)
    }

    /// Advances the player's position by one frame. `direction` is expected to already be
    /// magnitude <= 1 (see clampMagnitude); `speed` is in canvas points per second.
    static func move(from position: CGPoint, direction: CGVector, speed: CGFloat, deltaTime: TimeInterval, canvasSize: CGSize) -> CGPoint {
        let dt = CGFloat(deltaTime)
        let proposed = CGPoint(x: position.x + direction.dx * speed * dt, y: position.y + direction.dy * speed * dt)
        return clamp(proposed, in: canvasSize)
    }

    static func clamp(_ point: CGPoint, in canvasSize: CGSize) -> CGPoint {
        CGPoint(x: min(max(point.x, 0), canvasSize.width), y: min(max(point.y, 0), canvasSize.height))
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }

    static func nearestStation(to position: CGPoint, among stations: [WorldStationDefinition]) -> WorldStationDefinition? {
        stations.min { distance(position, $0.position) < distance(position, $1.position) }
    }

    static func isInRange(_ position: CGPoint, of station: WorldStationDefinition) -> Bool {
        distance(position, station.position) <= station.interactionRadius
    }

    /// The top-left of the visible viewport within the zone's canvas, following the player
    /// while staying clamped so the camera never scrolls past the canvas's edges (or goes
    /// negative when the canvas is smaller than the viewport, which would otherwise show
    /// empty space beyond the world).
    static func cameraOffset(playerPosition: CGPoint, canvasSize: CGSize, viewportSize: CGSize) -> CGPoint {
        let maxX = max(0, canvasSize.width - viewportSize.width)
        let maxY = max(0, canvasSize.height - viewportSize.height)
        let x = min(max(playerPosition.x - viewportSize.width / 2, 0), maxX)
        let y = min(max(playerPosition.y - viewportSize.height / 2, 0), maxY)
        return CGPoint(x: x, y: y)
    }
}
