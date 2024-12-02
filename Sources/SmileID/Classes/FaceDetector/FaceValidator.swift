import Foundation

protocol FaceValidatorDelegate: AnyObject {
    func updateValidationResult(_ result: FaceValidationResult)
}

struct FaceValidationResult {
    let userInstruction: SelfieCaptureInstruction?
    let hasDetectedValidFace: Bool
    let faceInBounds: Bool
}

final class FaceValidator {
    weak var delegate: FaceValidatorDelegate?
    private var faceLayoutGuideFrame: CGRect = .zero

    // MARK: Constants
    private let faceQualityThreshold: Float = 0.25
    private let luminanceThreshold: ClosedRange<Int> = 40...200
    private let selfiefaceBoundsMultiplier: CGFloat = 1.5
    private let livenessfaceBoundsMultiplier: CGFloat = 2.2
    private let faceBoundsThreshold: CGFloat = 50

    init() {}

    func setLayoutGuideFrame(with frame: CGRect) {
        self.faceLayoutGuideFrame = frame
    }

    func validate(
        faceGeometry: FaceGeometryData,
        faceQuality: Float,
        currentLivenessTask: LivenessTask?
    ) {
        // check face bounds
        let faceBoundsState = checkFaceSizeAndPosition(
            using: faceGeometry.boundingBox,
            shouldCheckCentering: currentLivenessTask == nil
        )
        let isAcceptableBounds = faceBoundsState == .detectedFaceAppropriateSizeAndPosition

        // check face quality
        let isAcceptableFaceQuality = checkFaceQuality(faceQuality)

        // check that face is ready for capture
        let hasDetectedValidFace = checkValidFace(
            isAcceptableBounds,
            isAcceptableFaceQuality
        )

        // determine what instruction/animation to display to users
        let userInstruction = userInstruction(
            from: faceBoundsState,
            detectedValidFace: hasDetectedValidFace,
            isAcceptableFaceQuality: isAcceptableFaceQuality,
            livenessTask: currentLivenessTask
        )

        let validationResult = FaceValidationResult(
            userInstruction: userInstruction,
            hasDetectedValidFace: hasDetectedValidFace,
            faceInBounds: isAcceptableBounds
        )
        delegate?.updateValidationResult(validationResult)
    }

    private func userInstruction(
        from faceBoundsState: FaceBoundsState,
        detectedValidFace: Bool,
        isAcceptableFaceQuality: Bool,
        livenessTask: LivenessTask?
    ) -> SelfieCaptureInstruction? {
        if detectedValidFace {
            if let livenessTask {
                switch livenessTask {
                case .lookLeft:
                    return .lookLeft
                case .lookRight:
                    return .lookRight
                case .lookUp:
                    return .lookUp
                }
            }
            return nil
        } else if faceBoundsState == .detectedFaceOffCentre {
            return .headInFrame
        } else if faceBoundsState == .detectedFaceTooSmall {
            return .moveCloser
        } else if faceBoundsState == .detectedFaceTooLarge {
            return .moveBack
        } else if !isAcceptableFaceQuality {
            return .goodLight
        }
        return nil
    }

    // MARK: Validation Checks
    private func checkFaceSizeAndPosition(
        using boundingBox: CGRect,
        shouldCheckCentering: Bool
    ) -> FaceBoundsState {
        let maxFaceWidth = faceLayoutGuideFrame.width - 20
        let faceBoundsMultiplier = shouldCheckCentering ? selfiefaceBoundsMultiplier : livenessfaceBoundsMultiplier
        let minFaceWidth = faceLayoutGuideFrame.width / faceBoundsMultiplier

        if boundingBox.width > maxFaceWidth {
            return .detectedFaceTooLarge
        } else if boundingBox.width < minFaceWidth {
            return .detectedFaceTooSmall
        }

        if shouldCheckCentering {
            let horizontalOffset = abs(boundingBox.midX - faceLayoutGuideFrame.midX)
            let verticalOffset = abs(boundingBox.midY - faceLayoutGuideFrame.midY)

            if horizontalOffset > faceBoundsThreshold || verticalOffset > faceBoundsThreshold {
                return .detectedFaceOffCentre
            }
        }

        return .detectedFaceAppropriateSizeAndPosition
    }

    private func checkFaceQuality(_ value: Float) -> Bool {
        return value >= faceQualityThreshold
    }

    private func checkValidFace(
        _ isAcceptableBounds: Bool,
        _ isAcceptableSelfieQuality: Bool
    ) -> Bool {
        return isAcceptableBounds && isAcceptableSelfieQuality
    }
}
