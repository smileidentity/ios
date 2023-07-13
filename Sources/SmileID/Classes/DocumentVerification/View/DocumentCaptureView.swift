import SwiftUI

struct DocumentCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DocumentCaptureViewModel
    var camera: CameraView
    init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        camera = CameraView(cameraManager: viewModel.cameraManager)
    }

    var body: some View {
        ZStack {
            camera
                .onAppear {
                    viewModel.cameraManager.switchCamera(to: .back)
                }
            DocumentOverlayView()
        } .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button {
                viewModel.resetState()
                viewModel.pauseCameraSession()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(uiImage: SmileIDResourcesHelper.ArrowLeft)
                    .padding()
            })
    }
}

struct DocumentCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureView(viewModel: DocumentCaptureViewModel())
    }
}
