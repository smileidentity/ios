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
    private let onDismiss: (() -> Void)?

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
        onResult: SmartSelfieResultDelegate,
        onDismiss: (() -> Void)? = nil
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
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if showInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: showAttribution,
                        viewModel: viewModel,
                        delegate: onResult
                    )
                } else {
                    SelfieCaptureScreen(viewModel: viewModel, delegate: onResult)
                }
            }
            .navigationBarItems(
                leading: Button {
                    onDismiss?()
                } label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                        .foregroundColor(SmileID.theme.accent)
                }
            )
        }
    }
}
