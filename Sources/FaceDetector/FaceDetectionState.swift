import Foundation

enum FaceDetectionState: Equatable {
    case sceneUnstable
    case finalFrame
    case multipleFacesDetected
    case faceDetected
    case noFaceDetected
    case faceDetectionErrored
}

enum FaceObservation<T: Equatable, E: Equatable>: Equatable {
    case faceFound(T)
    case faceNotFound
    case errored(E)
}

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case detectedFaceAppropriateSizeAndPosition
}

struct ErrorWrapper: Equatable {
    let error: Error

    public static func == (lhs: Self, rhs: Self) -> Bool {
        String(reflecting: lhs.error) == String(reflecting: rhs.error)
    }
}
