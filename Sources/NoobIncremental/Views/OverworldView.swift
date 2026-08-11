import SwiftUI

/// The walkable 2D scene for a zone — replaces the old NoobsTab. A joystick-driven player
/// walks around a fixed-size canvas; nearby stations (Noob generators, a zone-transition
/// gate) surface an interact prompt.
///
/// Body is split into small @ViewBuilder properties from the start rather than one large
/// ZStack — this project hit a real Swift type-checker timeout CI failure earlier this
/// session from exactly that pattern (see MoreSheet.statsSection's own split into
/// statsRows/shareProgressButton for the same reason).
struct OverworldView: View {
    @ObservedObject var viewModel: GameViewModel
    let layout: ZoneLayout

    @State private var playerPosition: CGPoint
    @State private var joystickDirection: CGVector = .zero
    @State private var isJoystickActive = false
    @State private var lastFrameDate: Date?
    @State private var nearbyStationID: String?
    @State private var activePopupGeneratorID: String?
    @State private var zoneGateMessage: String?
    @State private var showRebirthAltar = false
    @State private var showUpgradeWorkshop = false
    @State private var showRuneShrine = false

    init(viewModel: GameViewModel, layout: ZoneLayout) {
        self.viewModel = viewModel
        self.layout = layout
        _playerPosition = State(initialValue: layout.spawnPoint)
    }

    private var generators: [GeneratorRowViewData] { viewModel.generatorRows }

    private var isTargetZoneUnlocked: (String) -> Bool {
        { targetZoneID in viewModel.worldRows.first(where: { $0.id == targetZoneID })?.isUnlocked ?? false }
    }

    private var nearbyStation: WorldStationDefinition? {
        layout.stations.first { $0.id == nearbyStationID }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                worldLayer(viewportSize: geo.size)
                movementDriver
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottom) { controlsOverlay }
        }
        .sheet(isPresented: activePopupPresentedBinding) {
            if let generatorID = activePopupGeneratorID, let data = generators.first(where: { $0.id == generatorID }) {
                GeneratorStationPopupView(
                    generator: data,
                    onBuy: { viewModel.buyGenerator(generatorID, $0) },
                    onBuyMax: { viewModel.buyGeneratorMax(generatorID) }
                )
            }
        }
        .sheet(isPresented: $showRebirthAltar) {
            RebirthAltarSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showUpgradeWorkshop) {
            UpgradeWorkshopSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showRuneShrine) {
            RuneShrineSheet(viewModel: viewModel)
        }
        .alert("Locked", isPresented: zoneGateAlertBinding, presenting: zoneGateMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - World (camera-followed canvas)

    private func worldLayer(viewportSize: CGSize) -> some View {
        let cameraOffset = PlayerMovementSystem.cameraOffset(playerPosition: playerPosition, canvasSize: layout.canvasSize, viewportSize: viewportSize)
        return canvasContent
            .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
            .offset(x: -cameraOffset.x, y: -cameraOffset.y)
    }

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            WorldBackdrop(zoneID: layout.zoneID)
                .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
            stationMarkersLayer
            PlayerAvatarView(size: 56)
                .position(playerPosition)
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
    }

    @ViewBuilder
    private var stationMarkersLayer: some View {
        ForEach(layout.stations) { station in
            StationMarkerView(station: station, isNearby: station.id == nearbyStationID)
                .position(station.position)
        }
    }

    // MARK: - Movement loop

    /// Drives continuous position updates only while the joystick is actively held —
    /// TimelineView (not a second Timer) so it's view-scoped and torn down automatically,
    /// and completely independent of GameViewModel's own economy tick. Mutating @State
    /// directly inside a TimelineView's content closure during view-body evaluation is
    /// unsafe; onChange(of: context.date) is the correct place to actually advance state.
    private var movementDriver: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isJoystickActive)) { context in
            Color.clear
                .onChange(of: context.date) { _, newDate in
                    advanceFrame(now: newDate)
                }
        }
        .allowsHitTesting(false)
    }

    private func advanceFrame(now: Date) {
        defer { lastFrameDate = now }
        guard let last = lastFrameDate else { return }
        let deltaTime = now.timeIntervalSince(last)
        // Cross the canvas top-to-bottom in ~4s — pacing scales automatically if canvasSize
        // is ever tuned later, rather than needing a separately-tuned hardcoded speed.
        let speed = layout.canvasSize.height / 4.0
        playerPosition = PlayerMovementSystem.move(from: playerPosition, direction: joystickDirection, speed: speed, deltaTime: deltaTime, canvasSize: layout.canvasSize)

        if let nearest = PlayerMovementSystem.nearestStation(to: playerPosition, among: layout.stations), PlayerMovementSystem.isInRange(playerPosition, of: nearest) {
            nearbyStationID = nearest.id
        } else {
            nearbyStationID = nil
        }
    }

    // MARK: - Controls (joystick + interact prompt)

    private var controlsOverlay: some View {
        HStack(alignment: .bottom) {
            VirtualJoystickView(direction: $joystickDirection, isActive: $isJoystickActive)
                .padding(.leading, 20)
                .padding(.bottom, 20)
            Spacer()
            if let station = nearbyStation {
                interactPrompt(for: station)
                    .padding(.trailing, 20)
                    .padding(.bottom, 28)
            }
        }
    }

    private func interactPrompt(for station: WorldStationDefinition) -> some View {
        Button {
            interact(with: station)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: station.icon)
                    .font(.title3)
                Text(station.name)
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.oofGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.black)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Visit \(station.name)")
    }

    private func interact(with station: WorldStationDefinition) {
        isJoystickActive = false
        switch station.kind {
        case .generator(let generatorID):
            activePopupGeneratorID = generatorID
        case .zoneTransition(let targetZoneID):
            zoneGateMessage = isTargetZoneUnlocked(targetZoneID)
                ? "\(station.name) is unlocked! It isn't walkable yet — for now, keep growing this zone."
                : "Rebirth to unlock \(station.name)."
        case .rebirthAltar:
            showRebirthAltar = true
        case .upgradeWorkshop:
            showUpgradeWorkshop = true
        case .runeShrine:
            showRuneShrine = true
        }
    }

    // MARK: - Sheet/alert bindings

    private var activePopupPresentedBinding: Binding<Bool> {
        Binding(get: { activePopupGeneratorID != nil }, set: { if !$0 { activePopupGeneratorID = nil } })
    }

    private var zoneGateAlertBinding: Binding<Bool> {
        Binding(get: { zoneGateMessage != nil }, set: { if !$0 { zoneGateMessage = nil } })
    }
}

private struct StationMarkerView: View {
    let station: WorldStationDefinition
    let isNearby: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: station.icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(isNearby ? Theme.oofGradient : LinearGradient(colors: [.white.opacity(0.25)], startPoint: .top, endPoint: .bottom), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))
            Text(station.name)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2)
        }
    }
}
