import Foundation

enum FaceDetectionState: Equatable {
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
    case detectedFaceNotWithinFrame
    case detectedFaceAppropriateSizeAndPosition
}

struct ErrorWrapper: Equatable {
    let error: Error

    public static func == (lhs: Self, rhs: Self) -> Bool {
        String(reflecting: lhs.error) == String(reflecting: rhs.error)
    }
}
