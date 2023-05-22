import SwiftUI
import Combine

public struct SelfieCaptureView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: SelfieCaptureViewModel
    let camera: CameraView
    private weak var delegate: SmartSelfieResultDelegate?

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.camera = CameraView(frameManager: viewModel.frameManager,
                                 cameraManager: viewModel.cameraManager)
    }

    // NB
    // TODO:only used for previews to remove lint issues
    fileprivate init(viewModel: SelfieCaptureViewModel) {
        self.viewModel = viewModel
        self.camera = CameraView(frameManager: viewModel.frameManager,
                                 cameraManager: viewModel.cameraManager)
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
                switch viewModel.processingState {
                case .confirmation:
                    ModalPresenter { SelfieConfirmationView(viewModel: viewModel)}
                case .inProgress:
                    ModalPresenter { ProcessingView() }
                case .success:
                    ModalPresenter { SuccessView(viewModel: viewModel) }
                case .error:
                    ModalPresenter { ErrorView(viewModel: viewModel) }
                case .none:
                    Text("")
                }

            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button {
            presentationMode.wrappedValue.dismiss()
            viewModel.resetCapture()
        } label: {
            Image(uiImage: SmileIDResourcesHelper.ArrowLeft)
                .padding()
        })
        .background(SmileIdentity.theme.backgroundMain)
    }

    private func ovalSize(from geometry: GeometryProxy) -> CGSize {
        return CGSize(width: geometry.size.width * 0.6,
                      height: geometry.size.width * 0.6 / 0.7)
    }
}

struct SelfieCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        SelfieCaptureView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                            sessionId: UUID().uuidString,
                                                            isEnroll: false))
    }
}

class DummyDelegate: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {}
    func didError(error: Error) {}
}
