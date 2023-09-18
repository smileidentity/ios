import SwiftUI

struct DocumentCaptureView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    @EnvironmentObject var router: Router<NavigationDestination>
    @Environment(\.presentationMode) var presentationMode
    var camera: CameraView
    init(viewModel: DocumentCaptureViewModel) {
        self.viewModel = viewModel
        camera = CameraView(cameraManager: viewModel.cameraManager)
        UINavigationBar.appearance().titleTextAttributes = [.font: EpilogueFont.boldUIFont(with: 16)!,
            .foregroundColor: SmileID.theme.accent.uiColor()]
    }

    var body: some View {
        if let processingState = viewModel.processingState, processingState == .endFlow {
            let _ = DispatchQueue.main.async {
                router.dismiss()
            }
        }

            VStack {
                ZStack {
                    camera
                        .onAppear {
                            viewModel.cameraManager.switchCamera(to: .back)
                            viewModel.rectangleDetectionDelegate = camera.preview
                            viewModel.router = router
                        }
                    DocumentOverlayView(viewModel: viewModel)
                }
                VStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .center, spacing: 16) {
                        Text(SmileIDResourcesHelper.localizedString(for: viewModel.captureSideCopy))
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header4)
                            .foregroundColor(SmileID.theme.accent)
                        Text(SmileIDResourcesHelper.localizedString(for: "Document.Clear"))
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.body)
                            .foregroundColor(SmileID.theme.accent)
                            .frame(width: 235, alignment: .center)
                    }
                    if viewModel.showCaptureButton {
                        CaptureButton {
                            viewModel.captureImage()
                        }.padding(.bottom, 60)
                    }
                }.frame(height: 230)
            }
            .padding(.top, 50)
            .overlay(NavigationBar {
                viewModel.resetState()
                viewModel.pauseCameraSession()
                router.pop()
            })
            .edgesIgnoringSafeArea(.all)
    }

    func handleBackButtonTap() {
        viewModel.pauseCameraSession()
    }
}

struct DocumentCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentCaptureView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                jobId: "",
                                                                document: Document(countryCode: "",
                                                                                   documentType: "",
                                                                                   aspectRatio: 0.2),
                                                                captureBothSides: true,
                                                                showAttribution: true,
                                                                allowGalleryUpload: true))
    }
}


