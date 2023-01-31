import SwiftUI
import AVFoundation
import Vision

protocol FaceDetectorDelegate: AnyObject {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

struct CameraView: UIViewControllerRepresentable {
  typealias UIViewType = PreviewView
    let preview = PreviewView()
    @StateObject private var model = ContentViewModel()

    func makeUIViewController(context: Context) -> PreviewView {
        return preview
    }

    func updateUIViewController(_ uiViewController: PreviewView, context: Context) { }
}
