import SwiftUI

struct SelfieActionsView: View {
    var retryAction: () -> Void
    var cancelAction: () -> Void
    
    var body: some View {
        VStack {
            SmileButton(title: "Confirmation.Retry") {
                retryAction()
            }
            Button {
                cancelAction()
            } label: {
                Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                    .font(SmileID.theme.button)
                    .foregroundColor(SmileID.theme.error)
            }
            .padding(.top)
        }
        .padding(.horizontal, 65)
    }
}
