import SwiftUI

struct DocumentOverlayView: View {
    @State var aspectRatio: CGFloat = 1.0

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
                            .blendMode(.destinationOut)
                            .frame(width: docWidth, height: docHeight)
                            .border(Color.white, width: 10)
                        ,alignment: .center)
            }
            VStack {
                Spacer()
                HStack {
                    Text("Aspect Ratio: \(aspectRatio, specifier: "%.2f")")
                        .foregroundColor(.white)
                        .padding()
                    Slider(value: $aspectRatio, in: 0.5...2.0, step: 0.01)
                        .padding()
                }
                .background(Color.black.opacity(0.7))
                .padding()
            }
        }
    }
}

struct DocumentCaptureOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentOverlayView()
    }
}
