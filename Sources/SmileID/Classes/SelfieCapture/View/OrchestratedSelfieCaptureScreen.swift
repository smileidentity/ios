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
        self.viewModel.configure(delegate: onResult)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if showInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: config.showAttribution,
                        didTapTakePhoto: {
                            withAnimation { showInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    SelfieCaptureScreen(
                        jobId: config.jobId,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))

                    NavigationLink(
                        unwrap: $viewModel.processingState,
                        onNavigate: { _ in
                        },
                        destination: { $processingState in
                            ProcessingScreen(
                                processingState: processingState,
                                inProgressTitle: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.ProcessingSelfie"
                                ),
                                inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.Time"
                                ),
                                inProgressIcon: SmileIDResourcesHelper.FaceOutline,
                                successTitle: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.SelfieCaptureComplete"
                                ),
                                successSubtitle: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.SuccessBody"
                                ),
                                successIcon: SmileIDResourcesHelper.CheckBold,
                                errorTitle: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.Failure"
                                ),
                                errorSubtitle: getErrorSubtitle(
                                    errorMessageRes: viewModel.errorMessageRes,
                                    errorMessage: viewModel.errorMessage
                                ),
                                errorIcon: SmileIDResourcesHelper.Scan,
                                continueButtonText: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.Continue"
                                ),
                                onContinue: { viewModel.handleContinue() },
                                retryButtonText: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.Retry"
                                ),
                                onRetry: { viewModel.handleRetry() },
                                closeButtonText: SmileIDResourcesHelper.localizedString(
                                    for: "Confirmation.Close"
                                ),
                                onClose: { viewModel.handleClose() }
                            )
                        },
                        label: { EmptyView() }
                    )
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
