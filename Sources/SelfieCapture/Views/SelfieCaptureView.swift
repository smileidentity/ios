import SwiftUI
import Combine

public struct SelfieCaptureView: View {
    @StateObject private var viewModel = SelfieCaptureViewModel()
    let camera = CameraView()
    
    private var dividerWidth = UIScreen.main.bounds.width - 40
    public init() {}
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 14) {
                VStack(spacing: 20) {
                    ZStack{
                        camera
                            .clipShape(Ellipse())
                            .onAppear {
                                viewModel.faceLayoutGuideFrame = CGRect(origin: .zero,
                                                                        size: CGSize(width: geometry.size.width * 0.7,
                                                                                     height: geometry.size.width * 0.7 / (3/3.5)))
                                viewModel.viewDelegate = camera.preview
                            }
                        Ellipse()
                            .stroke(.blue, lineWidth: 8)
                        FaceBoundingBoxView(model: viewModel)
                    }
                    .frame(width: geometry.size.width * 0.7,
                           height: geometry.size.width * 0.7 / (3/3.5))
                    InstructionsView(model: viewModel)
                    Divider()
                        .frame(width: dividerWidth)
                }.padding(.top, 90)
                HStack {
                    Image(systemName: "info.circle.fill")
                        .frame(width: 32, height: 32)
                    Text("Put your face inside the oval frame and wait until it turns blue.")
                        .font(.system(size: 12))
                }.frame(maxWidth: 250)
                Spacer()
            }.frame(width: geometry.size.width,
                    height: geometry.size.height)
        }
    }
}

//struct SelfieCaptureView_Previews: PreviewProvider {
//    static var previews: some View {
//        SelfieCaptureView()
//    }
//}


struct FaceBoundingBoxView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel
    
    var body: some View {
        switch model.faceGeometryState {
        case .faceNotFound:
            Rectangle().fill(Color.clear)
        case .faceFound(let faceGeometryModel):
            Rectangle()
                .path(in: CGRect(
                    x: faceGeometryModel.boundingBox.origin.x,
                    y: faceGeometryModel.boundingBox.origin.y,
                    width: faceGeometryModel.boundingBox.width,
                    height: faceGeometryModel.boundingBox.height
                ))
                .stroke(Color.yellow, lineWidth: 2.0)
        case .errored:
            Rectangle().fill(Color.clear)
        }
    }
}

//struct FaceBoundingBoxView_Previews: PreviewProvider {
//    static var previews: some View {
//        FaceBoundingBoxView(model: SelfieCaptureViewModel())
//    }
//}
