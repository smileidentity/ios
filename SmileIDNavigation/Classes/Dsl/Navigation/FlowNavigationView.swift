import SwiftUI
import Combine
// MARK: - Flow Navigation View

/// Main navigation view for the SmileID flow
struct FlowNavigationView: View {
    let configuration: FlowConfiguration

    @ObservedObject private var navigationManager: FlowNavigationManager
    @ObservedObject private var isolatedContext: SmileIDIsolatedContext

    init(configuration: FlowConfiguration) {
        self.configuration = configuration
        _navigationManager = ObservedObject(wrappedValue: FlowNavigationManager(configuration: configuration))
        _isolatedContext = ObservedObject(wrappedValue: SmileIDIsolatedContext.shared)
    }
    
    var body: some View {
        NavigationView {
            startDestinationView
        }
        .environmentObject(navigationManager)
        .environmentObject(isolatedContext)
    }
    
    @ViewBuilder
    private var startDestinationView: some View {
        if let firstScreen = configuration.screens.first,
           navigationManager.navigationPath.isEmpty {
            screenView(for: firstScreen)
        } else if let currentType = navigationManager.navigationPath.last,
                  let screen = configuration.screens.first(where: { $0.type == currentType }) {
            screenView(for: screen)
        } else {
            Text("No screens configured")
        }
    }
    
    @ViewBuilder
    private func destinationView(for screenType: ScreenType) -> some View {
        if let screen = configuration.screens.first(where: { $0.type == screenType }) {
            screenView(for: screen)
        } else {
            Text("Screen not found")
        }
    }
    
    @ViewBuilder
    private func screenView(for screen: Screen) -> some View {
        switch screen.type {
        case .instructions:
            if let config = screen.configuration as? InstructionsScreenConfiguration {
                OrchestratedBuilderInstructionsScreen(configuration: config)
            }
        case .capture:
            if let config = screen.configuration as? CaptureScreenConfiguration {
                OrchestratedBuilderCaptureScreen(configuration: config)
            }
        case .preview:
            if let config = screen.configuration as? PreviewScreenConfiguration {
                OrchestratedBuilderPreviewScreen(configuration: config)
            }
        }
    }
}
