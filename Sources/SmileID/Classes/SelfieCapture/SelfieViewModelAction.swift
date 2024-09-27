import Foundation

enum SelfieViewModelAction {
    // View Setup Actions
    case windowSizeDetected(CGRect)

    // Face Detection Actions
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
    case selfieQualityObservationDetected(SelfieQualityModel)
    case updateUserInstruction(SelfieCaptureInstruction?)
    case activeLivenessCompleted
    case activeLivenessTimeout

    // Others
    case setupDelayTimer
    case toggleDebugMode
    case openApplicationSettings
    case handleError(Error)
}
