import SwiftUI

struct ProcessingView: View {

    var image: UIImage
    var titleKey: String
    var calloutKey: String
    var body: some View {

        VStack(spacing: 20) {
            InfiniteProgressBar()
                .frame(width: 60)
            Image(uiImage: image)
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: titleKey))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: calloutKey))
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                .lineSpacing(1.3)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 80)
        }
            .padding()
            .background(SmileID.theme.backgroundMain)
            .cornerRadius(20)
            .shadow(radius: 20)
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView(image: SmileIDResourcesHelper.FaceOutline,
                       titleKey: "Confirmation.ProcessingSelfie",
                       calloutKey: "Confirmation.Time")
    }
}
