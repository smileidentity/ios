import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedEnhancedSelfieCaptureScreen: View {
    public let showAttribution: Bool
    public let showInstructions: Bool
    public let onResult: SmartSelfieResultDelegate
    private let viewModel: EnhancedSmartSelfieViewModel

    public init(
        userId: String,
        isEnroll: Bool,
        allowNewEnroll: Bool,
        showAttribution: Bool,
        showInstructions: Bool,
        extraPartnerParams: [String: String],
        onResult: SmartSelfieResultDelegate
    ) {
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.onResult = onResult
        self.viewModel = EnhancedSmartSelfieViewModel(
            isEnroll: isEnroll,
            userId: userId,
            allowNewEnroll: allowNewEnroll,
            extraPartnerParams: extraPartnerParams,
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
