import UIKit
import Vision
import AVFoundation

class PreviewView: UIViewController {

    var layedOutSubviews = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var cameraManager: CameraManageable?

    init(cameraManager: CameraManageable) {
        self.cameraManager = cameraManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePreviewLayer()
    }

    func configurePreviewLayer() {
        guard let session = cameraManager?.session else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
    }
}

extension PreviewView: FaceDetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
      guard let previewLayer = previewLayer else {
          return .zero
      }
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
}
