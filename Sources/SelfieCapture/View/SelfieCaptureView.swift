import SwiftUI
import Combine

public struct SelfieCaptureView: View {
    @ObservedObject private var viewModel: SelfieCaptureViewModel
    let camera = CameraView()
    private weak var delegate: SmartSelfieResultDelegate?

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
    }

    public var body: some View {
        GeometryReader { geometry in
            let ovalSize = ovalSize(from: geometry)
            ZStack {
                camera
                    .onAppear {
                        viewModel.captureResultDelegate = delegate
                        viewModel.faceLayoutGuideFrame =
                        CGRect(origin: .zero,
                               size: ovalSize)
                        viewModel.viewDelegate = camera.preview
                        viewModel.viewFinderSize = geometry.size
                    }

                FaceOverlayView(model: viewModel)
            }
        }.edgesIgnoringSafeArea(.all)
    }

    private func ovalSize(from geometry: GeometryProxy) -> CGSize {
        return CGSize(width: geometry.size.width * 0.6,
                      height: geometry.size.width * 0.6 / 0.7)
    }
}

struct SelfieCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        SelfieCaptureView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString, sessionId: UUID().uuidString, isEnroll: false), delegate: DummyDelegate())
    }
}

class DummyDelegate: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: Data, livenessImages: [Data]) {}
    func didError(error: Error) {}
}


import SwiftUI

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

struct FaceBoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        FaceBoundingBoxView(model: SelfieCaptureViewModel(userId: "", sessionId: "", isEnroll: true))
    }
}
