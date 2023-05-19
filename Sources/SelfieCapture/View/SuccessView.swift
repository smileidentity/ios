import SwiftUI

struct SuccessView: View {
    @ObservedObject var viewModel: SelfieCaptureViewModel

    var body: some View {

        VStack(spacing: 20) {
            Image(uiImage: SmileIDResourcesHelper.CheckBold)
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.SelfieCaptureComplete"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header4)
                    .foregroundColor(SmileIdentity.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.SuccessBody"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
            SmileButton(style: .primary,
                        title: "Confirmation.Continue",
                        clicked: {
                viewModel.handleSuccess()
            })
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}

struct SuccessView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SelfieCaptureViewModel(userId: "",
                                               sessionId: "",
                                               isEnroll: true)
        SuccessView(viewModel: viewModel)
    }
}