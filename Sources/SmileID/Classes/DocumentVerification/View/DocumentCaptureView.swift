import SwiftUI

struct DocumentCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DocumentCaptureViewModel
    var camera: CameraView
    init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        camera = CameraView(cameraManager: viewModel.cameraManager)
        UINavigationBar.appearance().titleTextAttributes = [.font: EpilogueFont.boldUIFont(with: 16)!,
            .foregroundColor: SmileID.theme.accent.uiColor()]

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
            .navigationBarTitle(viewModel.navTitle)
    }
}

struct DocumentCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                jobId: "",
                                                                document: Document(countryCode: "",
                                                                                   documentType: "",
                                                                                   aspectRatio: 0.2)))
    }
}


