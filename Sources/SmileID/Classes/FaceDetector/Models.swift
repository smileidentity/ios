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
    case detectedFaceAppropriateSizeAndPosition
}

enum ActiveLivenessStage: CaseIterable {
    case lookLeft
    case lookRight
    case lookUp
    
    var maxValue: CGFloat {
        switch self {
        case .lookLeft:
            return 30.0
        case .lookRight:
            return -30.0
        case .lookUp:
            return 15.0
        }
    }
}

struct ErrorWrapper: Equatable {
    let error: Error

    public static func == (lhs: Self, rhs: Self) -> Bool {
        String(reflecting: lhs.error) == String(reflecting: rhs.error)
    }
}
