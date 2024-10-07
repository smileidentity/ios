import SwiftUI

struct SelfieProcessingView: View {
    var model: SelfieViewModelV2
    var didTapRetry: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack {
            VStack {
                Text(SmileIDResourcesHelper.localizedString(for: "Submitting"))
                    .font(SmileID.theme.header2)
                Text(SmileIDResourcesHelper.localizedString(for: "Your authentication failed"))
                    .font(SmileID.theme.body)
            }
            .foregroundColor(SmileID.theme.accent)
            .padding(.top, 40)

            ZStack(alignment: .center) {
                Circle()
                    .fill(Color(hex: "060606"))
                CircularProgressView()
            }
            .frame(width: 260, height: 260)
            .padding(.top, 40)

            Spacer()

            SmileButton(title: "Confirmation.Retry") {
                self.didTapRetry()
            }

            SmileButton(title: "Action.Done") {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
        .navigationBarHidden(true)
    }
}
