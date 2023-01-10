import Foundation

enum FaceDetectionState {
    case faceDetected
    case noFaceDetected
    case faceDetectionErrored
}

enum FaceObservation<T> {
    case faceFound(T)
    case faceNotFound
    case errored(Error)
}

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case detectedFaceAppropriateSizeAndPosition
}
