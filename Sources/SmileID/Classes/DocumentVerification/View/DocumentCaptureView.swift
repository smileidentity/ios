import SwiftUI

struct DocumentCaptureView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    @EnvironmentObject var navigationViewModel: NavigationViewModel
    @Environment(\.presentationMode) var presentationMode
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
                    viewModel.rectangleDetectionDelegate = camera.preview
                }
            DocumentOverlayView(viewModel: viewModel)
            switch viewModel.processingState {
            case .confirmation(let image):
                let _ = viewModel.cropImage(image, quadView: camera.preview.quadView)
                ModalPresenter { DocumentConfirmationView(viewModel: viewModel)}
            case .inProgress:
                ModalPresenter(centered: true) { ProcessingView(image: SmileIDResourcesHelper.Scan,
                                                                titleKey: "Document.Processing.Header",
                                                                calloutKey: "Document.Processing.Callout")
                }
            case .complete:
                ModalPresenter { SuccessView(titleKey: "Document.Complete.Header",
                                             bodyKey: "Document.Complete.Callout",
                                             clicked: { viewModel.handleCompletion() }) }
            case .error:
                ModalPresenter { ErrorView(viewModel: viewModel) }
            default:
                Color.clear
            }
        }
        .edgesIgnoringSafeArea(.all)
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
        DocumentCaptureView(viewModel: DocumentCaptureViewModel(userId: "",
                                                                jobId: "",
                                                                document: Document(countryCode: "",
                                                                                   documentType: "",
                                                                                   aspectRatio: 0.2),
                                                                captureBothSides: true))
    }
}


