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

    // MARK: Constants
    private let selfieQualityThreshold: Float = 0.5
    private let luminanceThreshold: ClosedRange<Int> = 80...200
    private let faceBoundsMultiplier: CGFloat = 1.2
    private let faceBoundsThreshold: CGFloat = 50

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
        let faceBoundsState = checkAcceptableBounds(using: faceGeometry.boundingBox)
        let isAcceptableBounds = faceBoundsState == .detectedFaceAppropriateSizeAndPosition

        // 2 - check brightness
        let isAcceptableBrightness = luminanceThreshold.contains(brightness)

        // 3 - check selfie quality
        let isAcceptableSelfieQuality = checkSelfieQuality(selfieQuality)

        // 4 - check detected valid face that's ready for selfie capture
        let hasDetectedValidFace = checkValidFace(
            isAcceptableBounds,
            isAcceptableBrightness,
            isAcceptableSelfieQuality
        )

        // get instruction to show to the user
        let userInstruction = userInstruction(
            from: faceBoundsState,
            detectedValidFace: hasDetectedValidFace,
            isAcceptableBrightness: isAcceptableBrightness,
            isAcceptableSelfieQuality: isAcceptableSelfieQuality
        )

        let validationResult = FaceValidationResult(
            userInstruction: userInstruction,
            isAcceptableSelfieQuality: isAcceptableSelfieQuality,
            hasDetectedValidFace: hasDetectedValidFace
        )
        delegate?.updateValidationResult(validationResult)
    }

    private func userInstruction(
        from faceBoundsState: FaceBoundsState,
        detectedValidFace: Bool,
        isAcceptableBrightness: Bool,
        isAcceptableSelfieQuality: Bool
    ) -> SelfieCaptureInstruction? {
        if detectedValidFace {
            return nil
        } else if faceBoundsState == .detectedFaceTooSmall {
            return .moveCloser
        } else if faceBoundsState == .detectedFaceTooLarge {
            return .moveBack
        } else if faceBoundsState == .detectedFaceOffCentre {
            return .headInFrame
        } else if !isAcceptableSelfieQuality || !isAcceptableBrightness {
            return .goodLight
        }
        return nil
    }

    // MARK: Validation Checks
    private func checkAcceptableBounds(using boundingBox: CGRect) -> FaceBoundsState {
        if boundingBox.width > faceBoundsMultiplier * faceLayoutGuideFrame.width {
            return .detectedFaceTooLarge
        } else if boundingBox.width * faceBoundsMultiplier < faceLayoutGuideFrame.width {
            return .detectedFaceTooSmall
        } else {
            if abs(
                boundingBox.midX - faceLayoutGuideFrame.midX
            ) > faceBoundsThreshold {
                return .detectedFaceOffCentre
            } else if abs(boundingBox.midY - faceLayoutGuideFrame.midY) > faceBoundsThreshold {
                return .detectedFaceOffCentre
            } else {
                return .detectedFaceAppropriateSizeAndPosition
            }
        }
    }

    private func checkSelfieQuality(_ value: SelfieQualityData) -> Bool {
        return value.passed >= selfieQualityThreshold
    }

    private func checkValidFace(
        _ isAcceptableBounds: Bool,
        _ isAcceptableBrightness: Bool,
        _ isAcceptableSelfieQuality: Bool
    ) -> Bool {
        return isAcceptableBounds &&
        isAcceptableBrightness &&
        isAcceptableSelfieQuality
    }
}
