import SwiftUI

struct DocumentOverlayView: View {
    @State var aspectRatio: CGFloat = 1.66

    var body: some View {
        GeometryReader { geometry in
            let docWidth = geometry.size.width * 0.9
            let docHeight = docWidth / aspectRatio

            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: docWidth, height: docHeight)
                            .border(Color.white, width: 10)
                            .cornerRadius(16)
                            .blendMode(.destinationOut)
                        ,alignment: .center)
            }
            VStack(alignment: .center){
                VStack(alignment: .center, spacing: 16) {
                    Text("Front of National ID Card")
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.header4)
                        .foregroundColor(SmileID.theme.accent)
                        .frame(width: 235, alignment: .center)

                    Text("Make sure all corners are \n visible and there is no glare")
                        .multilineTextAlignment(.center)
                        .font(SmileID.theme.body)
                        .foregroundColor(SmileID.theme.accent)
                        .frame(width: 235, alignment: .center)
                }.position(x: geometry.frame(in: .local).midX, y: docHeight + 120)
                CaptureButton {

                }
                .position(x: geometry.frame(in: .local).midX,
                          y: geometry.size.height - 100)
//                HStack {
//                    Text("Aspect Ratio: \(aspectRatio, specifier: "%.2f")")
//                        .foregroundColor(.white)
//                        .padding()
//                    Slider(value: $aspectRatio, in: 0.5...2.0, step: 0.01)
//                        .padding()
//                }
//                .background(Color.black.opacity(0.7))
//                .padding()
            }
        }
    }
}

struct DocumentCaptureOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentOverlayView()
    }
}
