import SwiftUI

struct SubmissionStatusView: View {
    var processState: ProcessingState

    var body: some View {
        switch processState {
        case .inProgress:
            CircularProgressView()
                .frame(width: 48, height: 48)
        case .success:
            StatusImage("checkmark.circle.fill", color: SmileID.theme.success)
        case .error:
            StatusImage("xmark.circle.fill", color: SmileID.theme.error)
        }
    }

    // swiftlint:disable identifier_name
    @ViewBuilder func StatusImage(_ image: String, color: Color) -> some View {
        Image(systemName: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 48, height: 48)
            .foregroundColor(color)
    }
}
