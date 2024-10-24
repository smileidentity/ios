import SwiftUI

struct SelfieProcessingView: View {
    @ObservedObject var viewModel: SelfieViewModelV2

    @Environment(\.modalMode) private var modalMode

    var body: some View {
        VStack {
            VStack {
                Text(SmileIDResourcesHelper.localizedString(for: viewModel.processingState?.title ?? ""))
                    .font(SmileID.theme.header2)
                if let errorMessageRes = viewModel.errorMessageRes, !errorMessageRes.isEmpty {
                    Text(
                        SmileIDResourcesHelper.localizedString(
                            for: errorMessageRes)
                    )
                    .font(SmileID.theme.body)
                } else {
                    Text(
                        SmileIDResourcesHelper.localizedString(
                            for: viewModel.errorMessage ?? "")
                    )
                    .font(SmileID.theme.body)
                }
            }
            .foregroundColor(SmileID.theme.accent)
            .padding(.top, 40)

            switch viewModel.processingState {
            case .inProgress:
                ZStack(alignment: .center) {
                    Circle()
                        .fill(SmileID.theme.tertiary)
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
                SmileButton(title: "Confirmation.Continue") {
                    modalMode.wrappedValue = false
                    viewModel.perform(action: .jobProcessingDone)
                }
            case .error:
                Spacer()
                SmileButton(title: "Confirmation.Retry") {
                    viewModel.perform(action: .retryJobSubmission)
                }
                Button {
                    modalMode.wrappedValue = false
                    viewModel.perform(action: .jobProcessingDone)
                } label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.Close"))
                        .font(SmileID.theme.button)
                        .foregroundColor(SmileID.theme.accent)
                }
                .padding(.top)
            case .none:
                EmptyView()
            }
        }
        .padding()
        .navigationBarHidden(true)
    }
}
