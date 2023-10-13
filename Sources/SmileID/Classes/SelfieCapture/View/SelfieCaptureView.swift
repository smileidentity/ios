import SwiftUI
import Combine
import ARKit

public struct SelfieCaptureView: View, SelfieViewDelegate {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var router: Router<NavigationDestination>
    @ObservedObject var viewModel: SelfieCaptureViewModel
    private var delegate: SmartSelfieResultDelegate?
    var camera: CameraView?
    let arView: ARView?
    let faceOverlay: FaceOverlayView
    let showBackButton: Bool

    init(
        viewModel: SelfieCaptureViewModel,
        showBackButton: Bool = true,
        delegate: SmartSelfieResultDelegate?
    ) {
        self.delegate = delegate
        self.viewModel = viewModel
        self.showBackButton = showBackButton
        faceOverlay = FaceOverlayView(model: viewModel)
        viewModel.smartSelfieResultDelegate = delegate
        UIScreen.main.brightness = 1
        if ARFaceTrackingConfiguration.isSupported {
            arView = ARView()
            camera = CameraView(cameraManager: viewModel.cameraManager)
        } else {
            camera = CameraView(cameraManager: viewModel.cameraManager)
            arView = nil
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if ARFaceTrackingConfiguration.isSupported && viewModel.agentMode == false {
                    arView.onAppear {
                        arView?.preview.model = viewModel
                        viewModel.viewFinderSize = geometry.size
                        viewModel.selfieViewDelegate = self
                    }
                } else {
                    camera.onAppear {
                        viewModel.smartSelfieResultDelegate = delegate
                        viewModel.viewDelegate = camera!.preview
                        viewModel.viewFinderSize = geometry.size
                        viewModel.cameraManager.switchCamera(
                            to: viewModel.agentMode ? .back : .front
                        )
                    }
                }
                faceOverlay
                switch viewModel.processingState {
                case .confirmation:
                    ModalPresenter {
                        ImageConfirmationView(
                            viewModel: viewModel,
                            header: "Confirmation.GoodSelfie",
                            callout: "Confirmation.FaceClear",
                            confirmButtonTitle: "Confirmation.YesUse",
                            declineButtonTitle: "Confirmation.Retake",
                            image: UIImage(data: viewModel.displayedImage!)!
                        )
                    }
                case .inProgress:
                    ModalPresenter(centered: true) {
                        ProcessingView(
                            image: SmileIDResourcesHelper.FaceOutline,
                            titleKey: "Confirmation.ProcessingSelfie",
                            calloutKey: "Confirmation.Time"
                        )
                    }
                case .complete:
                    ModalPresenter {
                        SuccessView(
                            titleKey: "Confirmation.SelfieCaptureComplete",
                            bodyKey: "Confirmation.SuccessBody",
                            clicked: viewModel.handleCompletion
                        )
                    }
                case .error:
                    ModalPresenter { ErrorView(viewModel: viewModel) }
                default:
                    Color.clear
                }
            }
                .overlay(ZStack {
                    if (showBackButton) {
                        NavigationBar {
                            viewModel.resetState()
                            viewModel.pauseCameraSession()
                            router.pop()
                        }
                    }
                })
        }
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
            .background(SmileID.theme.backgroundMain)
            .onDisappear {
                viewModel.cameraManager.pauseSession()
            }
    }

    private func ovalSize(from geometry: GeometryProxy) -> CGSize {
        CGSize(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6 / 0.7)
    }

    func pauseARSession() {
        arView?.preview.pauseSession()
    }

    func resumeARSession() {
        arView?.preview.resumeSession()
    }
}

struct FaceBoundingBoxView: View {
    @ObservedObject private(set) var model: SelfieCaptureViewModel

    var body: some View {
        switch model.faceGeometryState {
        case .faceNotFound:
            Rectangle().fill(Color.clear)
        case .faceFound(let faceGeometryModel):
            Rectangle()
                .path(in: faceGeometryModel.boundingBox)
                .stroke(Color.yellow, lineWidth: 2.0)
        case .errored:
            Rectangle().fill(Color.yellow)
        }
    }
}
