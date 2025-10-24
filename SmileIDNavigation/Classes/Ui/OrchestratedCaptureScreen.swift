import SwiftUI

// Simplified capture screen aligning with FlowNavigationManager API.
// Uses navigateToNext to advance flow; configuration is required (non-optional).
struct OrchestratedBuilderCaptureScreen: View {
    let configuration: CaptureScreenConfiguration
    @EnvironmentObject private var navigationManager: FlowNavigationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Capture Screen")
                .font(.title)
            modeDetails(configuration)
            Button("Continue") {
                // Advance to next screen without a capture result (placeholder)
                navigationManager.navigateToNext(currentScreenType: .capture)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func modeDetails(_ config: CaptureScreenConfiguration) -> some View {
        switch config.mode {
        case .selfie:
            Text("Selfie Mode")
            if let selfieConfig = config.selfie {
                Text("Agent Mode: \(selfieConfig.allowAgentMode ? "Enabled" : "Disabled")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        case .document:
            Text("Document Mode")
            if let docConfig = config.document {
                Text("Both Sides: \(docConfig.captureBothSides ? "Yes" : "No")")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

