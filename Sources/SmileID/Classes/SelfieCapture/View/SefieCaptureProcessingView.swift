import SwiftUI

struct SelfieCaptureProcessingView: View {
    let processingState: ProcessingState
    let errorMessage: String
    let onContinue: () -> Void
    let onRetry: () -> Void
    let onClose: () -> Void

    init(
        processingState: ProcessingState,
        errorMessage: String,
        onContinue: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.processingState = processingState
        self.errorMessage = errorMessage
        self.onContinue = onContinue
        self.onRetry = onRetry
        self.onClose = onClose
    }

    var body: some View {
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
            errorSubtitle: errorMessage,
            errorIcon: SmileIDResourcesHelper.Scan,
            continueButtonText: SmileIDResourcesHelper.localizedString(
                for: "Confirmation.Continue"
            ),
            onContinue: onContinue,
            retryButtonText: SmileIDResourcesHelper.localizedString(
                for: "Confirmation.Retry"
            ),
            onRetry: onRetry,
            closeButtonText: SmileIDResourcesHelper.localizedString(
                for: "Confirmation.Close"
            ),
            onClose: onClose
        )
    }
}
