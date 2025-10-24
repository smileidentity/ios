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
        if let firstStep = configuration.steps.first,
           navigationManager.navigationPath.isEmpty {
            stepView(for: firstStep)
        } else if let currentType = navigationManager.navigationPath.last,
                  let step = configuration.steps.first(where: { $0.type == currentType }) {
            stepView(for: step)
        } else {
            Text("No screens configured")
        }
    }
    
    @ViewBuilder
    private func destinationView(for screenType: ScreenType) -> some View {
        if let step = configuration.steps.first(where: { $0.type == screenType }) {
            stepView(for: step)
        } else {
            Text("Screen not found")
        }
    }
    
    @ViewBuilder
    private func stepView(for step: FlowStep) -> some View {
        switch step {
        case .instructions(let config):
            OrchestratedBuilderInstructionsScreen(configuration: config)
        case .capture(let config):
            OrchestratedBuilderCaptureScreen(configuration: config)
        case .preview(let config):
            OrchestratedBuilderPreviewScreen(configuration: config)
        }
    }
}
