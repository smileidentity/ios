import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedSelfieCaptureScreenV2: View {
    public let allowAgentMode: Bool
    public let showAttribution: Bool
    public let showInstructions: Bool
    public let onResult: SmartSelfieResultDelegate
    @ObservedObject var viewModel: SelfieViewModelV2

    @State private var acknowledgedInstructions = false
    private var originalBrightness = UIScreen.main.brightness

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
        viewModel = SelfieViewModelV2()
    }

    public var body: some View {
        if showInstructions, !acknowledgedInstructions {
            SmartSelfieInstructionsScreen(showAttribution: showAttribution) {
                acknowledgedInstructions = true
            }
        } else {
            SelfieCaptureScreenV2(showAttribution: showAttribution)
        }
    }
}
