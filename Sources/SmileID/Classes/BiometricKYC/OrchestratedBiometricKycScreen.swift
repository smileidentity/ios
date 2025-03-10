import Combine
import SwiftUI

struct OrchestratedBiometricKycScreen: View {
    let config: BiometricVerificationConfig
    let delegate: BiometricKycResultDelegate
    @Backport.StateObject private var viewModel: OrchestratedBiometricKycViewModel
    var onDismiss: (() -> Void)?

    @State private var showSelfieCaptureInstructions: Bool

    init(
        config: BiometricVerificationConfig,
        delegate: BiometricKycResultDelegate,
        onDismiss: (() -> Void)? = nil
    ) {
        self.config = config
        self.delegate = delegate
        self.onDismiss = onDismiss
        self._viewModel = Backport.StateObject(wrappedValue: OrchestratedBiometricKycViewModel(
            config: config
        ))
        self._showSelfieCaptureInstructions = State(initialValue: config.showInstructions)
    }

    var body: some View {
        CancellableNavigationView {
            ZStack {
                selfieCaptureScreen

                NavigationLink(
                    unwrap: $viewModel.processingState,
                    onNavigate: { _ in },
                    destination: { $state in
                        ProcessingScreen(
                            processingState: state,
                            inProgressTitle: SmileIDResourcesHelper.localizedString(
                                for: "BiometricKYC.Processing.Title"
                            ),
                            inProgressSubtitle: SmileIDResourcesHelper.localizedString(
                                for: "BiometricKYC.Processing.Subtitle"
                            ),
                            inProgressIcon: SmileIDResourcesHelper.DocumentProcessing,
                            successTitle: SmileIDResourcesHelper.localizedString(
                                for: "BiometricKYC.Success.Title"
                            ),
                            successSubtitle: SmileIDResourcesHelper.localizedString(
                                for: "BiometricKYC.Success.Subtitle"
                            ),
                            successIcon: SmileIDResourcesHelper.CheckBold,
                            errorTitle: SmileIDResourcesHelper.localizedString(for: "BiometricKYC.Error.Title"),
                            errorSubtitle: getErrorSubtitle(
                                errorMessageRes: $viewModel.errorMessageRes.wrappedValue,
                                errorMessage: $viewModel.errorMessage.wrappedValue
                            ),
                            errorIcon: SmileIDResourcesHelper.Scan,
                            continueButtonText: SmileIDResourcesHelper.localizedString(
                                for: "Confirmation.Continue"
                            ),
                            onContinue: { viewModel.onFinished(delegate: delegate) },
                            retryButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Retry"),
                            onRetry: viewModel.onRetry,
                            closeButtonText: SmileIDResourcesHelper.localizedString(for: "Confirmation.Close"),
                            onClose: { viewModel.onFinished(delegate: delegate) }
                        )
                    },
                    label: { EmptyView() }
                )
            }
        } onCancel: {
            onDismiss?()
        }

    }

    private var selfieCaptureScreen: some View {
        ZStack {
            if config.useStrictMode {
                if showSelfieCaptureInstructions {
                    LivenessCaptureInstructionsView(
                        showAttribution: config.showAttribution,
                        didTapGetStarted: {
                            withAnimation { showSelfieCaptureInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    EnhancedSelfieCaptureScreen(
                        userId: config.userId,
                        showAttribution: config.showAttribution,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))
                }
            } else {
                if showSelfieCaptureInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: config.showAttribution,
                        didTapTakePhoto: {
                            withAnimation { showSelfieCaptureInstructions = false }
                        }
                    )
                    .transition(.move(edge: .leading))
                } else {
                    SelfieCaptureScreen(
                        jobId: config.jobId,
                        delegate: viewModel
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
    }
}
