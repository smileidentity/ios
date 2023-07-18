import SwiftUI

struct DocumentOverlayView: View {
    @State var aspectRatio: CGFloat = 1.66

    var body: some View {
        GeometryReader { geometry in
            let docWidth = geometry.size.width * 0.9
            let docHeight = docWidth / aspectRatio
            VStack(spacing: 15) {
                GeometryReader { geo in
                    VStack(spacing: 20) {
                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: docWidth, height: docHeight, alignment: .center)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .frame(width: docWidth, height: docHeight)
                                        .border(Color.gray, width: 10)
                                        .cornerRadius(16)
                                        .blendMode(.destinationOut)
                                    ,alignment: .center)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray,
                                            lineWidth: 10)
                                        .frame(width: docWidth, height: docHeight)
                                )

                        }
                        VStack(alignment: .center, spacing: 16) {
                            Text("Front of National ID Card")
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.header4)
                                .foregroundColor(SmileID.theme.accent)
                                .frame(width: 235, alignment: .center)
                            Text(SmileIDResourcesHelper.localizedString(for: "Document.Clear"))
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.body)
                                .foregroundColor(SmileID.theme.accent)
                                .frame(width: 235, alignment: .center)
                        }
                    }.position(CGPoint(x: geo.size.width/2,
                                       y: geo.size.height/2))

                }
                .padding(.top, window?.safeAreaInsets.top ?? 0 + 10)
                    CaptureButton {

                    }.padding(.bottom, 60)
            }
        }.background(Color.white.opacity(0.8))
    }
}

struct DocumentCaptureOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentOverlayView()
    }
}
