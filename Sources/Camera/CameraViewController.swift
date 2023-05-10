import UIKit
import Vision
import AVFoundation

class PreviewView: UIViewController {

    var layedOutSubviews = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraManager = CameraManager.shared

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if layedOutSubviews == false {
            configurePreviewLayer()
            layedOutSubviews = true
        }
    }

    func configurePreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        previewLayer?.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer!)
    }
}

extension PreviewView: FaceDetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
      guard let previewLayer = previewLayer else {
          return .zero
      }

        let normalizedRect = CGRect(x: rect.origin.y,
                                    y: rect.origin.x,
                                    width: rect.height,
                                    height: rect.width)

        let transformedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)

        let mirroredRect = CGRect(x: previewLayer.bounds.width - transformedRect.origin.x - transformedRect.width,
                                  y: previewLayer.bounds.height - transformedRect.origin.y - transformedRect.height,
                                  width: transformedRect.width,
                                  height: transformedRect.height)

        return mirroredRect

    }
}
