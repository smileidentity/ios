import UIKit
import Vision
import AVFoundation

class CameraViewController: UIViewController {
    var faceDetector: EnhancedFaceDetector?

    var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var cameraManager: CameraManager?

    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        faceDetector?.viewDelegate = self
        configurePreviewLayer()
    }

    func configurePreviewLayer() {
        guard let session = cameraManager?.session else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

extension CameraViewController: FaceDetectorViewDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        guard let previewLayer = previewLayer else {
            return CGRect.zero
        }
        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
}

extension CameraViewController: RectangleDetectionDelegate {
    func didDetectQuad(
        quad: Quadrilateral?,
        _ imageSize: CGSize,
        completion: ((Quadrilateral) -> Void)?
    ) {
        guard let quad else { return }
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        let scaleTransform = CGAffineTransform.scaleTransform(
            forSize: portraitImageSize,
            aspectFillInSize: view.bounds.size
        )
        let scaledImageSize = imageSize.applying(scaleTransform)
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)
        let translationTransform = CGAffineTransform.translateTransform(
            fromCenterOfRect: imageBounds,
            toCenterOfRect: view.bounds
        )
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        completion?(transformedQuad)
    }
}
