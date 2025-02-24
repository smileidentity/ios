import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedEnhancedSelfieCaptureScreen: View {
    private let viewModel: OrchestratedEnhancedSelfieCaptureViewModel

    private let config: OrchestratedSelfieCaptureConfig
    public let onResult: SmartSelfieResultDelegate
    private var onDismiss: (() -> Void)?

    @State private var showInstructions: Bool

    public init(
        config: OrchestratedSelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate,
        onDismiss: (() -> Void)? = nil
    ) {
        self.config = config
        self._showInstructions = State(initialValue: config.showInstructions)
        self.onResult = onResult
        self.onDismiss = onDismiss
        viewModel = OrchestratedEnhancedSelfieCaptureViewModel(
            config: config,
            localMetadata: LocalMetadata()
        )
        viewModel.configure(delegate: onResult)
    }

    public var body: some View {
        NavigationView {
            if showInstructions {
                LivenessCaptureInstructionsView(
                    showAttribution: config.showAttribution,
                    didTapGetStarted: {
                        showInstructions = false
                    }
                )
                .transition(.move(edge: .leading))
            } else {
                EnhancedSelfieCaptureScreen(
                    userId: config.userId,
                    showAttribution: config.showAttribution,
                    delegate: viewModel,
                    didTapCancel: {},
                    didTapRetry: {}
                )
                .transition(.move(edge: .trailing))
            }
        }
    }
}
