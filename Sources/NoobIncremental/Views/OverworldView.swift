import SwiftUI

/// The walkable 2D scene for a zone — replaces the old NoobsTab. A joystick-driven player
/// walks around a fixed-size canvas; nearby stations (Noob generators, the Rebirth Altar,
/// Upgrade Workshop, Rune Shrine, Minion Den, zone-transition gates) surface an interact
/// prompt.
///
/// `body` is kept to a handful of `.modifier(SomeType(...))` calls, each type-checked
/// independently, rather than one big chain of `.sheet`/`.alert` — this project hit a real
/// Swift type-checker timeout CI failure from exactly that pattern (first in
/// MoreSheet.statsSection, then again here once this view grew past two sheets). Splitting
/// into small `@ViewBuilder` properties wasn't sufficient on its own the second time; each
/// popup now lives in its own dedicated `ViewModifier` type instead.
struct OverworldView: View {
    @ObservedObject var viewModel: GameViewModel
    let layout: ZoneLayout
    /// Called when the player interacts with an unlocked zone-transition station. The
    /// caller is expected to apply `.id(zoneID)` to this view at the call site so SwiftUI
    /// tears down and recreates it (resetting playerPosition to the new zone's spawn point,
    /// clearing any open popups) rather than reusing this instance's @State across zones.
    let onTravel: (String) -> Void

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
    @State private var showMinionDen = false

    init(viewModel: GameViewModel, layout: ZoneLayout, onTravel: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.layout = layout
        self.onTravel = onTravel
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
        sceneContent
            .modifier(GeneratorPopupModifier(viewModel: viewModel, generators: generators, activePopupGeneratorID: $activePopupGeneratorID))
            .modifier(RebirthAndUpgradeSheetsModifier(viewModel: viewModel, showRebirthAltar: $showRebirthAltar, showUpgradeWorkshop: $showUpgradeWorkshop))
            .modifier(RuneAndMinionSheetsModifier(viewModel: viewModel, showRuneShrine: $showRuneShrine, showMinionDen: $showMinionDen))
            .modifier(ZoneGateAlertModifier(zoneGateMessage: $zoneGateMessage))
    }

    private var sceneContent: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                worldLayer(viewportSize: geo.size)
                movementDriver
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottom) { controlsOverlay }
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
            if isTargetZoneUnlocked(targetZoneID) {
                onTravel(targetZoneID)
            } else {
                zoneGateMessage = "Rebirth to unlock \(station.name)."
            }
        case .rebirthAltar:
            showRebirthAltar = true
        case .upgradeWorkshop:
            showUpgradeWorkshop = true
        case .runeShrine:
            showRuneShrine = true
        case .minionDen:
            showMinionDen = true
        }
    }
}

// MARK: - Popup modifiers (see the type-level doc comment for why these are split out)

private struct GeneratorPopupModifier: ViewModifier {
    let viewModel: GameViewModel
    let generators: [GeneratorRowViewData]
    @Binding var activePopupGeneratorID: String?

    private var isPresented: Binding<Bool> {
        Binding(get: { activePopupGeneratorID != nil }, set: { if !$0 { activePopupGeneratorID = nil } })
    }

    func body(content: Content) -> some View {
        content.sheet(isPresented: isPresented) {
            if let generatorID = activePopupGeneratorID, let data = generators.first(where: { $0.id == generatorID }) {
                GeneratorStationPopupView(
                    generator: data,
                    onBuy: { viewModel.buyGenerator(id: generatorID, quantity: $0) },
                    onBuyMax: { viewModel.buyGeneratorMax(id: generatorID) }
                )
            }
        }
    }
}

private struct RebirthAndUpgradeSheetsModifier: ViewModifier {
    let viewModel: GameViewModel
    @Binding var showRebirthAltar: Bool
    @Binding var showUpgradeWorkshop: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showRebirthAltar) { RebirthAltarSheet(viewModel: viewModel) }
            .sheet(isPresented: $showUpgradeWorkshop) { UpgradeWorkshopSheet(viewModel: viewModel) }
    }
}

private struct RuneAndMinionSheetsModifier: ViewModifier {
    let viewModel: GameViewModel
    @Binding var showRuneShrine: Bool
    @Binding var showMinionDen: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showRuneShrine) { RuneShrineSheet(viewModel: viewModel) }
            .sheet(isPresented: $showMinionDen) { MinionDenSheet(viewModel: viewModel) }
    }
}

private struct ZoneGateAlertModifier: ViewModifier {
    @Binding var zoneGateMessage: String?

    private var isPresented: Binding<Bool> {
        Binding(get: { zoneGateMessage != nil }, set: { if !$0 { zoneGateMessage = nil } })
    }

    func body(content: Content) -> some View {
        content.alert("Locked", isPresented: isPresented, presenting: zoneGateMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
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
