import Foundation
import SwiftUI

public enum ProcessingState {
    case inProgress
    case success
    case error
}

public struct ProcessingScreen: View {
    public init(
        processingState: ProcessingState,
        inProgressTitle: String,
        inProgressSubtitle: String,
        inProgressIcon: UIImage,
        successTitle: String,
        successSubtitle: String,
        successIcon: UIImage,
        errorTitle: String,
        errorSubtitle: String,
        errorIcon: UIImage,
        continueButtonText: String,
        onContinue: @escaping () -> Void,
        retryButtonText: String,
        onRetry: @escaping () -> Void,
        closeButtonText: String,
        onClose: @escaping () -> Void) {
            self.processingState = processingState
            self.inProgressTitle = inProgressTitle
            self.inProgressSubtitle = inProgressSubtitle
            self.inProgressIcon = inProgressIcon
            self.successTitle = successTitle
            self.successSubtitle = successSubtitle
            self.successIcon = successIcon
            self.errorTitle = errorTitle
            self.errorSubtitle = errorSubtitle
            self.errorIcon = errorIcon
            self.continueButtonText = continueButtonText
            self.onContinue = onContinue
            self.retryButtonText = retryButtonText
            self.onRetry = onRetry
            self.closeButtonText = closeButtonText
            self.onClose = onClose
        }
    let processingState: ProcessingState
    let inProgressTitle: String
    let inProgressSubtitle: String
    let inProgressIcon: UIImage
    let successTitle: String
    let successSubtitle: String
    let successIcon: UIImage
    let errorTitle: String
    let errorSubtitle: String
    let errorIcon: UIImage
    let continueButtonText: String
    let onContinue: () -> Void
    let retryButtonText: String
    let onRetry: () -> Void
    let closeButtonText: String
    let onClose: () -> Void
    public var body: some View {
        switch processingState {
        case .inProgress:
            ProcessingInProgressScreen(
                icon: inProgressIcon,
                title: inProgressTitle,
                subtitle: inProgressSubtitle
            )
        case .success:
            ProcessingSuccessScreen(
                icon: successIcon,
                title: successTitle,
                subtitle: successSubtitle,
                continueButtonText: continueButtonText,
                onContinue: onContinue
            )
        case .error:
            ProcessingErrorScreen(
                icon: errorIcon,
                title: errorTitle,
                subtitle: errorSubtitle,
                retryButtonText: retryButtonText,
                onRetry: onRetry,
                closeButtonText: closeButtonText,
                onClose: onClose
            )
        }
    }
}

public struct ProcessingInProgressScreen: View {
    let icon: UIImage
    let title: String
    let subtitle: String
    public var body: some View {
        VStack(spacing: 20) {
            InfiniteProgressBar()
                .frame(width: 60)
            Image(uiImage: icon)
            VStack(spacing: 16) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 80)
        }
        .padding()
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(24)
        .shadow(radius: 16)
        .padding(32)
    }
}

private struct ProcessingSuccessScreen: View {
    let icon: UIImage
    let title: String
    let subtitle: String
    let continueButtonText: String
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: icon)
            VStack(spacing: 16) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)

                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 80)
            Button(action: onContinue) {
                Text(continueButtonText)
                    .font(SmileID.theme.button)
                    .foregroundColor(SmileID.theme.backgroundMain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SmileID.theme.accent)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(24)
        .shadow(radius: 16)
        .padding(32)
    }
}

public struct ProcessingErrorScreen: View {
    let icon: UIImage
    let title: String
    let subtitle: String
    let retryButtonText: String
    let onRetry: () -> Void
    let closeButtonText: String
    let onClose: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: icon)
            VStack(spacing: 16) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)

                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 80)
            Button(action: onRetry) {
                Text(retryButtonText)
                    .font(SmileID.theme.button)
                    .foregroundColor(SmileID.theme.backgroundMain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SmileID.theme.accent)
                    .cornerRadius(20)
            }
            Button(action: onClose) {
                Text(closeButtonText)
                    .font(SmileID.theme.button)
                    .foregroundColor(SmileID.theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SmileID.theme.backgroundMain)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(24)
        .shadow(radius: 16)
        .padding(32)
    }
}
