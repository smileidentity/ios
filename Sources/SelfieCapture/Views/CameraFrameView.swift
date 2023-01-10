import SwiftUI

struct CameraFrameView: View {
    var image: CGImage?
    let test = "Test"
    private let label = Text("Video feed")

    var body: some View {
        if let image {
            GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: .upMirrored, label: label)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width,
                           height: geometry.size.height,
                           alignment: .center)
                    .clipped()
            }
        } else {
            Color.black
        }
    }
}

struct FrameView_Previews: PreviewProvider {
    static var previews: some View {
        CameraFrameView()
    }
}
