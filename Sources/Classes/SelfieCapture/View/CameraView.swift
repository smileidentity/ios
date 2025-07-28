import AVFoundation
import SwiftUI
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

  func makeUIViewController(context _: Context) -> CameraViewController {
    cameraViewController
  }

  func updateUIViewController(_: CameraViewController, context _: Context) {}
}
