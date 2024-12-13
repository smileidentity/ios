import SwiftUI

struct SelfieActionsView: View {
    var captureState: EnhancedSmartSelfieViewModel.SelfieCaptureState
    var retryAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        VStack {
            switch captureState {
            case .capturingSelfie:
                cancelButton
            case .processing(let processingState):
                switch processingState {
                case .inProgress:
                    cancelButton
                case .success:
                    EmptyView()
                case .error:
                    SmileButton(title: "Confirmation.Retry") {
                        retryAction()
                    }
                    cancelButton
                }
            }
        }
        .padding(.horizontal, 65)
    }

    var cancelButton: some View {
        Button {
            cancelAction()
        } label: {
            Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                .font(SmileID.theme.button)
                .foregroundColor(SmileID.theme.error)
        }
    }
}
