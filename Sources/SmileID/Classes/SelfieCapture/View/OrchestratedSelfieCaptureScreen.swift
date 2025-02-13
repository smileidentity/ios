import Foundation
import SwiftUI

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedSelfieCaptureScreen: View {
    @Backport.StateObject private var viewModel: OrchestratedSelfieCaptureViewModel

    private let config: OrchestratedSelfieCaptureConfig
    private let onResult: SmartSelfieResultDelegate
    private let onDismiss: (() -> Void)?

    @State private var showInstructions: Bool

    public init(
        config: OrchestratedSelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate,
        onDismiss: (() -> Void)? = nil
    ) {
        self._showInstructions = State(initialValue: config.showInstructions)
        self.config = config
        self.onResult = onResult
        self.onDismiss = onDismiss
        self._viewModel = Backport
            .StateObject(
                wrappedValue: OrchestratedSelfieCaptureViewModel(
                    config: config
                )
            )
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if showInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: config.showAttribution,
                        delegate: onResult,
                        didTapTakePhoto: {
                            withAnimation { showInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    SelfieCaptureScreen(
                        isEnroll: config.isEnroll,
                        jobId: config.jobId,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))
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
