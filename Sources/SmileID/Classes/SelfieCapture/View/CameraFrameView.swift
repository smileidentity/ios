import SwiftUI
import AVFoundation
import Vision

protocol FaceDetectorDelegate: AnyObject {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewType = PreviewView
    let preview: PreviewView
    @ObservedObject private var model: ContentViewModel

    init(cameraManager: CameraManageable) {
        preview = PreviewView(cameraManager: cameraManager)
        model = ContentViewModel(cameraManager: cameraManager)
    }

    func makeUIViewController(context: Context) -> PreviewView {
        preview
    }

    func updateUIViewController(_ uiViewController: PreviewView, context: Context) {}
}
