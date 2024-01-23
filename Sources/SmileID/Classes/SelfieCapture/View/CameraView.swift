import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewType = PreviewView
    let preview: PreviewView

    init(cameraManager: CameraManageable) {
        preview = PreviewView(cameraManager: cameraManager)
    }

    func makeUIViewController(context: Context) -> PreviewView {
        preview
    }

    func updateUIViewController(_ uiViewController: PreviewView, context: Context) {}
}
