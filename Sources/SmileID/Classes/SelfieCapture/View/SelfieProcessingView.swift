import SwiftUI

struct SelfieProcessingView: View {
    var processingState: ProcessingState
    var errorMessage: String?
    var didTapRetry: () -> Void

    @Environment(\.modalMode) private var modalMode

    var body: some View {
        VStack {
            VStack {
                Text(SmileIDResourcesHelper.localizedString(for: processingState.title))
                    .font(SmileID.theme.header2)
                Text(SmileIDResourcesHelper.localizedString(for: errorMessage ?? ""))
                    .font(SmileID.theme.body)
            }
            .foregroundColor(SmileID.theme.accent)
            .padding(.top, 40)

            switch processingState {
            case .inProgress:
                ZStack(alignment: .center) {
                    Circle()
                        .fill(Color(hex: "060606"))
                    CircularProgressView()
                }
                .frame(width: 260, height: 260)
                .padding(.top, 40)

                Spacer()
            case .success:
                ZStack(alignment: .center) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .foregroundColor(SmileID.theme.success)
                }
                .frame(width: 260, height: 260)
                .padding(.top, 40)

                Spacer()
                SmileButton(title: "Action.Done") {
                    self.modalMode.wrappedValue = false
                }
            case .error:
                Spacer()
                SmileButton(title: "Confirmation.Retry") {
                    self.didTapRetry()
                }
            }
        }
        .padding()
        .navigationBarHidden(true)
    }
}
