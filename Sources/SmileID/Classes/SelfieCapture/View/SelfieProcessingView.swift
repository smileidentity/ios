import SwiftUI

struct SelfieProcessingView: View {
    var model: SelfieViewModelV2
    @State private var images: [UIImage] = []

    var body: some View {
        VStack {
            Text(SmileIDResourcesHelper.localizedString(for: "Submitting"))
                .font(SmileID.theme.header4)
            Text(SmileIDResourcesHelper.localizedString(for: "Your authentication failed"))
                .font(SmileID.theme.header4)
            ZStack {
                Circle()
                    .fill()
                    .frame(width: 260, height: 260)
                    .padding(.top, 40)
                if #available(iOS 14.0, *) {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    // Fallback on earlier versions
                }
            }
            Spacer()
            SmileButton(title: "Confirmation.Retry") {
                print("Retry button tapped")
            }
        }
    }

    private func loadImages() {
        images = model.livenessImages.compactMap {
            loadImage(from: $0)
        }
    }

    private func loadImage(from url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
