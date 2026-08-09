import SwiftUI

@main
struct NoobIncrementalApp: App {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.start()
            case .background, .inactive:
                viewModel.stop()
            @unknown default:
                break
            }
        }
    }
}
