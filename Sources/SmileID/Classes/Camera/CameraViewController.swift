import UIKit
import Vision
import AVFoundation

class PreviewView: UIViewController {
    let quadView = QuadrilateralView()
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
        quadView.translatesAutoresizingMaskIntoConstraints = false
        quadView.editable = false
        view.addSubview(quadView)
        setupConstraints()
    }

    func configurePreviewLayer() {
        guard let session = cameraManager?.session else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
    }

    private func setupConstraints() {
        var quadViewConstraints = [NSLayoutConstraint]()

        quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: quadView.trailingAnchor),
            quadView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]
        NSLayoutConstraint.activate(quadViewConstraints)
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

extension PreviewView: RectangleDetectionDelegate {
    func didDetectQuad(quad: Quadrilateral?, _ imageSize: CGSize) {
        guard let quad else {
            quadView.removeQuadrilateral()
            return
        }
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize,
                                                              aspectFillInSize: quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)
        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds,
                                                                        toCenterOfRect: quadView.bounds)

        let transforms = [scaleTransform, rotationTransform, translationTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }
}
