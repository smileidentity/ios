import UIKit
import Vision
import AVFoundation

class PreviewView: UIViewController {

    var layedOutSubviews = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var cameraManager: CameraManager?

    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if layedOutSubviews == false {
            configurePreviewLayer()
            layedOutSubviews = true
        }
    }

    func configurePreviewLayer() {
        guard let session = cameraManager?.session else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        previewLayer?.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer!)
    }
}

extension PreviewView {
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
