import SwiftUI
import Combine
import ARKit

public struct SelfieCaptureView: View, SelfieViewDelegate {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var router: Router<NavigationDestination>
    @ObservedObject var viewModel: SelfieCaptureViewModel
    private var delegate: SmartSelfieResultDelegate?
    private var originalBrightness: CGFloat
    var camera: CameraView?
    let arView: ARView?
    let faceOverlay: FaceOverlayView

    init(
        viewModel: SelfieCaptureViewModel,
        delegate: SmartSelfieResultDelegate?
    ) {
        self.delegate = delegate
        self.viewModel = viewModel
        faceOverlay = FaceOverlayView(model: viewModel)
        viewModel.smartSelfieResultDelegate = delegate
        originalBrightness = UIScreen.main.brightness
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
                case .confirmation(let selfieImage):
                    ModalPresenter {
                        ImageConfirmationView(
                            viewModel: viewModel,
                            header: "Confirmation.GoodSelfie",
                            callout: "Confirmation.FaceClear",
                            confirmButtonTitle: "Confirmation.YesUse",
                            declineButtonTitle: "Confirmation.Retake",
                            image: UIImage(data: selfieImage)!
                        )
                    }
                case .inProgress:
                    ModalPresenter {
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
        }
            .background(SmileID.theme.backgroundMain)
            .onDisappear {
                UIScreen.main.brightness = originalBrightness
                viewModel.cameraManager.pauseSession()
            }
    }

    func pauseARSession() {
        arView?.preview.pauseSession()
    }

    func resumeARSession() {
        arView?.preview.resumeSession()
    }
}
