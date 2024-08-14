import Foundation

enum SelfieViewModelAction {
    // Face Detection Actions
    case noFaceDetected
    case faceObservationDetected(FaceGeometryModel)
    
    // Others
    case toggleDebugMode
    case openApplicationSettings
    case handleError(Error)
}
