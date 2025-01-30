import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedSelfieCaptureScreen: View {
    public let allowAgentMode: Bool
    public let showAttribution: Bool
    public let showInstructions: Bool
    public let onResult: SmartSelfieResultDelegate
    private let viewModel: SelfieViewModel

    public init(
        userId: String,
        jobId: String,
        isEnroll: Bool,
        allowNewEnroll: Bool,
        allowAgentMode: Bool,
        showAttribution: Bool,
        showInstructions: Bool,
        extraPartnerParams: [String: String],
        skipApiSubmission: Bool,
        onResult: SmartSelfieResultDelegate
    ) {
        self.allowAgentMode = allowAgentMode
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.onResult = onResult
        viewModel = SelfieViewModel(
            isEnroll: isEnroll,
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            allowAgentMode: allowAgentMode,
            skipApiSubmission: skipApiSubmission,
            extraPartnerParams: extraPartnerParams,
            localMetadata: LocalMetadata()
        )
    }

    public var body: some View {
        if showInstructions {
            SmartSelfieInstructionsScreen(
                showAttribution: showAttribution,
                viewModel: viewModel
            )
        } else {
            SelfieCaptureScreen(viewModel: viewModel)
        }
    }
}
