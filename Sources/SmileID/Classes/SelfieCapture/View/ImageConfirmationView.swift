import SwiftUI

protocol ConfirmationDialogContract {
    func acceptImage()
    func declineImage()
}

struct ImageConfirmationView: View {
    var viewModel: ConfirmationDialogContract
    var header: String
    var callout: String
    var confirmButtonTitle: LocalizedStringKey
    var declineButtonTitle: LocalizedStringKey
    var image: UIImage

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: header))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header2)
                    .foregroundColor(SmileID.theme.accent)
                    .lineSpacing(0.98)

                Text(SmileIDResourcesHelper.localizedString(for: callout))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaleEffect(1.25)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(16)
                    .clipped()
            }

            VStack(spacing: 16) {
                SmileButton(
                    style: .secondary,
                    title: confirmButtonTitle,
                    clicked: viewModel.acceptImage
                )
                SmileButton(
                    style: .secondary,
                    title: declineButtonTitle,
                    clicked: viewModel.declineImage
                )
            }
        }
            .padding()
            .background(SmileID.theme.backgroundMain)
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}
