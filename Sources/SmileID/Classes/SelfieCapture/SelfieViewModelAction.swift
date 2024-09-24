import Foundation

enum SelfieViewModelAction {
    // View Setup Actions
    case windowSizeDetected(CGRect)

    // Face Detection Actions
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
    case selfieQualityObservationDetected(SelfieQualityModel)
    case activeLivenessCompleted
    case activeLivenessTimeout

    // Others
    case setupDelayTimer
    case toggleDebugMode
    case openApplicationSettings
    case handleError(Error)
}
