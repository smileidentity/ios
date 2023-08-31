import SwiftUI

struct DocumentCaptureView: View {
    @ObservedObject var viewModel: DocumentCaptureViewModel
    @EnvironmentObject var navigationViewModel: NavigationViewModel
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
                navigationViewModel.dismiss()
            }
        }
        VStack{
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
                CaptureButton {
                    viewModel.captureImage()
                }.padding(.bottom, 60)
            }.frame(height: 230)

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

    func displayModals() -> any View {
        switch viewModel.processingState {
        case .confirmation(let image):
            let _ = viewModel.cropImage(image, quadView: camera.preview.quadView)
            return ModalPresenter { ImageConfirmationView(viewModel: viewModel,
                                                          header: "Document.Confirmation.Header",
                                                          callout: "Document.Confirmation.Callout",
                                                          confirmButtonTitle: "Document.Confirmation.Accept",
                                                          declineButtonTitle:  "Document.Confirmation.Decline",
                                                          image: viewModel.confirmationImage)}
        case .inProgress:
            return ModalPresenter(centered: true) { ProcessingView(image: SmileIDResourcesHelper.Scan,
                                                                   titleKey: "Document.Processing.Header",
                                                                   calloutKey: "Document.Processing.Callout")
            }
        case .complete:
            return ModalPresenter { SuccessView(titleKey: "Document.Complete.Header",
                                                bodyKey: "Document.Complete.Callout",
                                                clicked: { viewModel.handleCompletion() })}
        case .error:
            return  ModalPresenter { ErrorView(viewModel: viewModel) }
        default:
            return Color.clear
        }
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


