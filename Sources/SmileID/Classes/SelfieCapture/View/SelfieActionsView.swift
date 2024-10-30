import SwiftUI

struct SelfieActionsView: View {
    var processingState: ProcessingState
    var retryAction: () -> Void
    var doneAction: () -> Void

    var body: some View {
        VStack {
            Spacer()
            switch processingState {
            case .inProgress:
                EmptyView()
            case .success:
                SmileButton(title: "Action.Done") {
                    doneAction()
                }
            case .error:
                SmileButton(title: "Confirmation.Retry") {
                    retryAction()
                }
            }
        }
        .padding(.horizontal, 65)
    }
}
