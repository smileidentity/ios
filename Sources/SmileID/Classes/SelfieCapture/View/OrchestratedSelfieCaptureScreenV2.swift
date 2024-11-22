import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedSelfieCaptureScreenV2: View {
    private let viewModel: SelfieViewModelV2

    private var originalBrightness = UIScreen.main.brightness

    public init(
        selfieCaptureConfig: SelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate
    ) {
        self.viewModel = SelfieViewModelV2(
            selfieCaptureConfig: selfieCaptureConfig,
            onResult: onResult,
            localMetadata: LocalMetadata()
        )
    }

    public var body: some View {
        if viewModel.selfieCaptureConfig.showInstructions {
            LivenessCaptureInstructionsView(
                showAttribution: viewModel.selfieCaptureConfig.showAttribution,
                viewModel: viewModel
            )
        } else {
            SelfieCaptureScreenV2(
                viewModel: viewModel,
                showAttribution: viewModel.selfieCaptureConfig.showAttribution
            )
        }
    }
}
