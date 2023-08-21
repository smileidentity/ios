import SwiftUI

struct DocumentConfirmationView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    @EnvironmentObject var navigationViewModel: NavigationViewModel

    var body: some View {
        VStack(spacing: 49) {
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Document.Confirmation.Header"))                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header2)
                    .foregroundColor(SmileID.theme.accent)
                    .lineSpacing(0.98)
                Text(SmileIDResourcesHelper.localizedString(for: "Document.Confirmation.Callout"))                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }

            Image(uiImage: viewModel.frontImage ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(16)
                .clipped()

            VStack(spacing: 16) {
                SmileButton(style: .secondary,
                            title: "Document.Confirmation.Accept",
                            clicked: { viewModel.submit(navigation: navigationViewModel) })
                SmileButton(style: .secondary,
                            title: "Document.Confirmation.Decline",
                            clicked: { viewModel.handleDeclineButtonTap() })
            }
        }
        .padding()
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}

struct DocumentConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentConfirmationView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                     jobId: "",
                                                                     document: Document(countryCode: "",
                                                                                        documentType: "",
                                                                                        aspectRatio: 0.0),
                                                                     captureBothSides: true, showAttribution: true))
    }
}
