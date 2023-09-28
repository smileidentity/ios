import SwiftUI

struct SuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    var titleKey: String
    var bodyKey: String
    var clicked: () -> Void
    var body: some View {

        VStack(spacing: 20) {
            Image(uiImage: SmileIDResourcesHelper.CheckBold)
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: titleKey))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: bodyKey))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            SmileButton(
                style: .primary,
                title: "Confirmation.Continue",
                clicked: clicked
            )
        }
            .padding()
            .background(SmileID.theme.backgroundMain)
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}

struct SuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessView(
            titleKey: "Confirmation.SelfieCaptureComplete",
            bodyKey: "Confirmation.SuccessBody",
            clicked: {}
        )
    }
}
