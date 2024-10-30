import SwiftUI

struct SelfieActionsView: View {
    var processingState: ProcessingState?
    var retryAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        VStack {
            if let processingState = processingState,
                processingState == .error {
                SmileButton(title: "Confirmation.Retry") {
                    retryAction()
                }
            }
            Spacer()
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
