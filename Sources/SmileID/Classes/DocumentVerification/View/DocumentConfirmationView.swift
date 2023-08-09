import SwiftUI

struct DocumentConfirmationView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    var body: some View {
        VStack(alignment: .center, spacing: 49) {
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Document.Confirmation.Header"))                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header1)
                    .foregroundColor(SmileID.theme.accent)
                    .lineSpacing(0.98)
                Text(SmileIDResourcesHelper.localizedString(for: "Document.Confirmation.Callout"))                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }

            Image("")

            VStack(spacing: 16) {
                SmileButton(style: .secondary,
                            title: "Document.Confirmation.Accept",
                            clicked: { viewModel.submit() })
                SmileButton(style: .secondary,
                            title: "Document.Confirmation.Decline",
                            clicked: { viewModel.handleDeclineButtonTap() })
            }
        }
    }
}

struct DocumentConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentConfirmationView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                     jobId: "",
                                                                     document: Document(countryCode: "",
                                                                                        documentType: "",
                                                                                        aspectRatio: 0.0)))
    }
}
