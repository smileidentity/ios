import Foundation

protocol FaceValidatorDelegate: AnyObject {
    func updateInstruction(_ instruction: SelfieCaptureInstruction?)
}

final class FaceValidator {
    var faceLayoutGuideFrame = CGRect(x: 0, y: 0, width: 200, height: 300)
    weak var delegate: FaceValidatorDelegate?
    
    // MARK: Publishers for Vision data
    private(set) var hasDetectedValidFace: Bool
    private var faceDetectedState: FaceDetectionState {
        didSet {
            determineDirective()
        }
    }
    private var faceGeometryState: FaceObservation<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    private var faceQualityState: FaceObservation<FaceQualityModel> {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    private var selfieQualityState: FaceObservation<SelfieQualityModel> {
        didSet {
            processUpdatedSelfieQuality()
        }
    }
    private var isAcceptableBounds: FaceBoundsState {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    private var isAcceptableFaceQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }
    private var isAcceptableSelfieQuality: Bool {
        didSet {
            calculateDetectedFaceValidity()
        }
    }

    init() {
        self.hasDetectedValidFace = false
        self.faceDetectedState = .noFaceDetected
        self.faceGeometryState = .faceNotFound
        self.faceQualityState = .faceNotFound
        self.selfieQualityState = .faceNotFound
        self.isAcceptableBounds = .unknown
        self.isAcceptableFaceQuality = false
        self.isAcceptableSelfieQuality = false
    }

    // MARK: Perform Checks
    func determineDirective() {
        switch faceDetectedState {
        case .faceDetected:
            if hasDetectedValidFace {
                delegate?.updateInstruction(nil)
            } else if isAcceptableBounds == .detectedFaceTooSmall {
                delegate?.updateInstruction(.moveCloser)
            } else if isAcceptableBounds == .detectedFaceTooLarge {
                delegate?.updateInstruction(.moveBack)
            } else if isAcceptableBounds == .detectedFaceOffCentre {
                delegate?.updateInstruction(.headInFrame)
            } else if !isAcceptableSelfieQuality {
                delegate?.updateInstruction(.goodLight)
            }
        case .noFaceDetected:
            delegate?.updateInstruction(.headInFrame)
        case .faceDetectionErrored:
            delegate?.updateInstruction(nil)
        }
    }

    func processUpdatedFaceGeometry() {
        switch faceGeometryState {
        case let .faceFound(faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            updateAcceptableBounds(using: boundingBox)
        case .faceNotFound:
            invalidateFaceGeometryState()
        case let .errored(error):
            print(error.localizedDescription)
            invalidateFaceGeometryState()
        }
    }

    func invalidateFaceGeometryState() {
        // This is where we reset all the face geometry values.
        isAcceptableBounds = .unknown
    }

    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooLarge
        } else if boundingBox.width * 1.2 < faceLayoutGuideFrame.width {
            isAcceptableBounds = .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                isAcceptableBounds = .detectedFaceOffCentre
            } else {
                isAcceptableBounds = .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    func processUpdatedFaceQuality() {
        switch faceQualityState {
        case let .faceFound(faceQualityModel):
            // Check acceptable range here.
            isAcceptableFaceQuality = faceQualityModel.quality > 0.2
        case .faceNotFound:
            isAcceptableFaceQuality = false
        case let .errored(error):
            print(error.localizedDescription)
            isAcceptableFaceQuality = false
        }
    }

    func processUpdatedSelfieQuality() {
        switch selfieQualityState {
        case let .faceFound(selfieQualityModel):
            // Check acceptable range here.
            isAcceptableSelfieQuality = selfieQualityModel.passed > 0.5
        case .faceNotFound:
            isAcceptableSelfieQuality = false
        case let .errored(error):
            print(error.localizedDescription)
            isAcceptableSelfieQuality = false
        }
    }

    func calculateDetectedFaceValidity() {
        hasDetectedValidFace =
            isAcceptableBounds == .detectedFaceAppropriateSizeAndPosition && isAcceptableFaceQuality
            && isAcceptableSelfieQuality
    }
}
