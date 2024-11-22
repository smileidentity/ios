import Foundation

enum SelfieCaptureState: Equatable {
    case capturingSelfie
    case processing(ProcessingState)

    var title: String {
        switch self {
        case .capturingSelfie:
            return "Instructions.Capturing"
        case let .processing(processingState):
            return processingState.title
        }
    }
}
