import SwiftUI
struct ErrorView: View {
    @ObservedObject var viewModel: SelfieCaptureViewModel
    var body: some View {

        VStack(spacing: 20) {
            Image(uiImage: SmileIDResourcesHelper.Scan)
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Failure"))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.FaulireReason"))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            VStack(spacing: 5) {
                SmileButton(style: .primary,
                            title: "Confirmation.Retry",
                            clicked: {
                    viewModel.handleRetry()
                })
                SmileButton(style: .destructive,
                            title: "Confirmation.Close",
                            clicked: {
                    viewModel.handleClose()
                })
            }

        }
        .padding()
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}
