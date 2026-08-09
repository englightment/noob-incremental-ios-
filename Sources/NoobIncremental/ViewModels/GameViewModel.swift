import Foundation
import UIKit
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var lastOfflineEarnings: Decimal?

    private let saveManager: SaveManager
    private var tickTimer: Timer?
    private var autosaveTimer: Timer?
    private var lastTickDate = Date()
    private let tapHaptic = UIImpactFeedbackGenerator(style: .medium)

    var formattedCurrency: String { NumberFormatting.format(state.currency) }

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let loaded = saveManager.load()
        let offline = OfflineProgress.apply(to: loaded)
        self.state = offline.state
        self.lastOfflineEarnings = offline.currencyEarned > 0 ? offline.currencyEarned : nil
        tapHaptic.prepare()
    }

    func start() {
        lastTickDate = Date()
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: GameBalance.tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: GameBalance.autosaveInterval, repeats: true) { [weak self] _ in
            self?.save()
        }
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
        autosaveTimer?.invalidate()
        autosaveTimer = nil
        save()
    }

    func tap() {
        state = GameLoop.applyTap(state)
        tapHaptic.impactOccurred()
    }

    func dismissOfflineEarningsBanner() {
        lastOfflineEarnings = nil
    }

    private func tick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickDate)
        lastTickDate = now
        state = GameLoop.tick(state, elapsed: elapsed)
    }

    private func save() {
        var toSave = state
        toSave.lastSaveTimestamp = Date()
        state = toSave
        saveManager.save(toSave)
    }
}
