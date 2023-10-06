import Foundation
import SwiftUI

struct ProcessingScreen: View {
    let processingState: DocumentProcessingState
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

    var body: some View {
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

private struct ProcessingInProgressScreen: View {
    let icon: UIImage
    let title: String
    let subtitle: String

    var body: some View {
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
            .cornerRadius(20)
            .shadow(radius: 20)
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
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}

private struct ProcessingErrorScreen: View {
    let icon: UIImage
    let title: String
    let subtitle: String
    let retryButtonText: String
    let onRetry: () -> Void
    let closeButtonText: String
    let onClose: () -> Void

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
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}
