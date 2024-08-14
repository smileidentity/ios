import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewType = CameraViewController
    let preview: CameraViewController

    init(cameraManager: CameraManager) {
        preview = CameraViewController(cameraManager: cameraManager)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        preview
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
