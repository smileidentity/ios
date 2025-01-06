import SwiftUI

struct SubmissionStatusView: View {
    var processState: ProcessingState

    var body: some View {
        switch processState {
        case .inProgress:
            CircularProgressView()
                .frame(width: 48, height: 48)
        case .success:
            StatusImage(SmileIDResourcesHelper.Checkmark)
        case .error:
            StatusImage(SmileIDResourcesHelper.Xmark)
        }
    }

    // swiftlint:disable identifier_name
    @ViewBuilder func StatusImage(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 48, height: 48)
    }
}
