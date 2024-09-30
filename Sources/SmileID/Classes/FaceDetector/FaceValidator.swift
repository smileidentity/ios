import Foundation

protocol FaceValidatorDelegate: AnyObject {
    func updateValidationResult(_ result: FaceValidationResult)
}

struct FaceValidationResult {
    let userInstruction: SelfieCaptureInstruction?
    let isAcceptableSelfieQuality: Bool
    let hasDetectedValidFace: Bool
}

final class FaceValidator {
    weak var delegate: FaceValidatorDelegate?
    private var faceLayoutGuideFrame: CGRect = .zero
    private let selfieQualityThreshold: Float = 0.5
    private var faceBoundsState: FaceBoundsState = .unknown
    private var isAcceptableSelfieQuality: Bool = false
    private var hasDetectedValidFace: Bool = false

    init() {}

    func setLayoutGuideFrame(with frame: CGRect) {
        self.faceLayoutGuideFrame = frame
    }

    func validate(
        faceGeometry: FaceGeometryData,
        selfieQuality: SelfieQualityData,
        brightness: Int
    ) {
        // process the values and perform validation checks
        // 1 - check face bounds
        faceBoundsState = checkAcceptableBounds(using: faceGeometry.boundingBox)
        // 2 - check selfie quality
        isAcceptableSelfieQuality = checkSelfieQuality(selfieQuality)

        // 3 - check detected valid face that's ready for selfie capture
        hasDetectedValidFace = checkValidFace(brightness: brightness)
    }

    private func invalidateFaceGeometryState() {
        faceBoundsState = .unknown
    }

    private func publishValidationResult(faceGeometryData: FaceGeometryData) {
        let userInstruction = getUserInstruction(from: faceGeometryData)
        let validationResult = FaceValidationResult(
            userInstruction: userInstruction,
            isAcceptableSelfieQuality: isAcceptableSelfieQuality,
            hasDetectedValidFace: hasDetectedValidFace
        )
        delegate?.updateValidationResult(validationResult)
    }

    private func getUserInstruction(from faceGeometryData: FaceGeometryData) -> SelfieCaptureInstruction? {
        if hasDetectedValidFace {
            return nil
        } else if faceBoundsState == .detectedFaceTooSmall {
            return .moveCloser
        } else if faceBoundsState == .detectedFaceTooLarge {
            return .moveBack
        } else if faceBoundsState == .detectedFaceOffCentre {
            return .headInFrame
        } else if !isAcceptableSelfieQuality {
            return .goodLight
        }
        return nil
    }

    // MARK: Validation Checks
    private func checkAcceptableBounds(using boundingBox: CGRect) -> FaceBoundsState {
        if boundingBox.width > 1.2 * faceLayoutGuideFrame.width {
            return .detectedFaceTooLarge
        } else if boundingBox.width * 1.2 < faceLayoutGuideFrame.width {
            return .detectedFaceTooSmall
        } else {
            if abs(boundingBox.midX - faceLayoutGuideFrame.midX) > 50 {
                return .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > 50 {
                return .detectedFaceOffCentre
            } else {
                return .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    private func checkSelfieQuality(_ value: SelfieQualityData) -> Bool {
        return value.passed >= selfieQualityThreshold
    }

    private func checkValidFace(brightness: Int) -> Bool {
        return faceBoundsState == .detectedFaceAppropriateSizeAndPosition &&
        isAcceptableSelfieQuality &&
        brightness > 80 && brightness < 200
    }
}
