import Foundation

enum SelfieViewModelAction {
    // Face Detection Actions
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    case faceQualityObservationDetected(FaceQualityModel)
    case selfieQualityObservationDetected(SelfieQualityModel)

    // Others
    case toggleDebugMode
    case openApplicationSettings
    case handleError(Error)
}
