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

    init( cameraManager: CameraManager) {
        self.preview = PreviewView(cameraManager: cameraManager)
        self.model = ContentViewModel(cameraManager: cameraManager)
    }

    func makeUIViewController(context: Context) -> PreviewView {
        return preview
    }

    func updateUIViewController(_ uiViewController: PreviewView, context: Context) { }
}
