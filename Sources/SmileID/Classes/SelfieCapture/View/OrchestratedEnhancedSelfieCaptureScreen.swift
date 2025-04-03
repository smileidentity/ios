import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedEnhancedSelfieCaptureScreen: View {
    @Backport.StateObject private var viewModel: OrchestratedEnhancedSelfieCaptureViewModel

    private let config: OrchestratedSelfieCaptureConfig
    public let onResult: SmartSelfieResultDelegate

    @State private var showInstructions: Bool

    public init(
        config: OrchestratedSelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate
    ) {
        self.config = config
        self._showInstructions = State(initialValue: config.showInstructions)
        self.onResult = onResult
        self._viewModel = Backport.StateObject(wrappedValue: OrchestratedEnhancedSelfieCaptureViewModel(
            config: config,
            localMetadata: LocalMetadata()
        ))
        self.viewModel.configure(delegate: onResult)
    }

    public var body: some View {
        CancellableNavigationView {
            ZStack {
                if showInstructions {
                    LivenessCaptureInstructionsView(
                        showAttribution: config.showAttribution,
                        didTapGetStarted: {
                            showInstructions = false
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    ZStack {
                        if let processingState = viewModel.processingState {
                            EnhancedSelfieCaptureStatusView(
                                processingState: processingState,
                                errorMessage: processingState == .error ? getErrorSubtitle(
                                    errorMessageRes: viewModel.errorMessageRes,
                                    errorMessage: viewModel.errorMessage
                                ) : nil,
                                selfieImage: viewModel.selfieImage,
                                showAttribution: config.showAttribution,
                                didTapCancel: { viewModel.handleCancel() },
                                didTapRetry: { viewModel.handleRetry() }
                            )
                        } else {
                            EnhancedSelfieCaptureScreen(
                                userId: config.userId,
                                showAttribution: config.showAttribution,
                                delegate: viewModel,
                                didTapCancel: { viewModel.handleCancel() }
                            )
                        }
                    }
                    .transition(.move(edge: .trailing))
                }
            }
        } onCancel: {
            viewModel.handleCancel()
        }
    }
}
