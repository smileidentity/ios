import SwiftUI
import Combine

public struct SelfieCaptureView: View {
    @StateObject private var model = ContentViewModel()

    private var dividerWidth = UIScreen.main.bounds.width - 40
    public init() {}
    public var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 20) {
                ZStack{
                    CameraFrameView(image: model.frame)
                        .clipShape(Ellipse())
                    Ellipse()
                        .stroke(.blue, lineWidth: 8)
                }
                .frame(width: 172, height: 196)               
                Text("Smile for the camera")
                    .font(.system(size: 16))
                Divider()
                    .frame(width: 250)
            }
            HStack {
                Image(systemName: "info.circle.fill")
                    .frame(width: 32, height: 32)
                Text("Put your face inside the oval frame and wait until it turns blue.")
                    .font(.system(size: 12))
            }.frame(maxWidth: 250)
        }
    }
}

struct SelfieCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        SelfieCaptureView()
    }
}
