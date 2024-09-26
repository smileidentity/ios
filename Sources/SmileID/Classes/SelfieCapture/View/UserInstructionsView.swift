import SwiftUI

struct UserInstructionsView: View {
    @ObservedObject var viewModel: SelfieViewModelV2

    var body: some View {
        VStack {
            Text(SmileIDResourcesHelper.localizedString(for: viewModel.directive))
                .multilineTextAlignment(.center)
                .font(SmileID.theme.header2)
                .foregroundColor(SmileID.theme.accent)
                .padding(.top, 40)
                .padding(.horizontal, 50)
            Spacer()
        }
        .padding()
    }
}
