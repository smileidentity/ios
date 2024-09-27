import Foundation

enum SelfieCaptureInstruction {
    case headInFrame
    case moveBack
    case moveCloser
    case lookStraight
    case goodLight
    case lookLeft
    case lookRight
    case lookUp
    
    var instruction: String {
        switch self {
        case .headInFrame:
            return "Position your head in view"
        case .moveCloser:
            return "Move closer"
        case .moveBack:
            return "Move back"
        case .lookStraight:
            return "Position your head in view"
        case .goodLight:
            return "Move to a well lit room"
        case .lookLeft:
            return "Turn your head to the left"
        case .lookRight:
            return "Turn your head to the right"
        case .lookUp:
            return "Turn your head slightly up"
        }
    }
    
    var guideAnimation: CaptureGuideAnimation {
        switch self {
        case .headInFrame:
            return .headInFrame
        case .moveCloser:
            return .moveCloser
        case .moveBack:
            return .moveBack
        case .lookStraight:
            return .headInFrame
        case .goodLight:
            return .goodLight
        case .lookLeft:
            return .lookLeft
        case .lookRight:
            return .lookRight
        case .lookUp:
            return .lookUp
        }
    }
}
