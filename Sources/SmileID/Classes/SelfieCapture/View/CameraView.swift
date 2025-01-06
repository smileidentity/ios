import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewType = CameraViewController
    let cameraViewController: CameraViewController

    init(
        cameraManager: CameraManager,
        selfieViewModel: EnhancedSmartSelfieViewModel? = nil
    ) {
        let controller = CameraViewController(cameraManager: cameraManager)
        controller.faceDetector = selfieViewModel?.faceDetector
        cameraViewController = controller
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
