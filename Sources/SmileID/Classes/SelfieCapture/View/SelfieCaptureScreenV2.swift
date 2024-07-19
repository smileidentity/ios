import SwiftUI

struct SelfieCaptureScreenV2: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "face.smiling")
                .font(.largeTitle)
            Text("Look up")
                .font(SmileID.theme.header2)
                .foregroundColor(.primary)
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.black, lineWidth: 10.0)
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(.black.opacity(0.2))
                Ellipse()
                    .frame(width: 220, height: 280)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(width: 300, height: 400)

            Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
        }
    }
}

#if DEBUG
#Preview {
    SelfieCaptureScreenV2()
}
#endif
