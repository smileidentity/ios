import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedEnhancedSelfieCaptureScreen: View {
    public let allowAgentMode: Bool
    public let showAttribution: Bool
    public let showInstructions: Bool
    public let onResult: SmartSelfieResultDelegate
    private let viewModel: EnhancedSmartSelfieViewModel

    public init(
        userId: String,
        jobId: String,
        isEnroll: Bool,
        allowNewEnroll: Bool,
        allowAgentMode: Bool,
        showAttribution: Bool,
        showInstructions: Bool,
        useStrictMode: Bool,
        extraPartnerParams: [String: String],
        skipApiSubmission: Bool,
        onResult: SmartSelfieResultDelegate
    ) {
        self.allowAgentMode = allowAgentMode
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.onResult = onResult
        self.viewModel = EnhancedSmartSelfieViewModel(
            isEnroll: isEnroll,
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            skipApiSubmission: skipApiSubmission,
            extraPartnerParams: extraPartnerParams,
            useStrictMode: useStrictMode,
            onResult: onResult,
            localMetadata: LocalMetadata()
        )
    }

    public var body: some View {
        if showInstructions {
            LivenessCaptureInstructionsView(
                showAttribution: showAttribution,
                viewModel: viewModel
            )
        } else {
            EnhancedSelfieCaptureScreen(
                viewModel: viewModel,
                showAttribution: showAttribution
            )
        }
    }
}
