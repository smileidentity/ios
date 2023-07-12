import SwiftUI

struct DocumentCaptureView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    var camera: CameraView
    init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        camera = CameraView(cameraManager: viewModel.cameraManager)
    }

    var body: some View {
        GeometryReader { geometry in
            camera
        }
    }
}

struct DocumentCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureView(viewModel: DocumentCaptureViewModel())
    }
}
