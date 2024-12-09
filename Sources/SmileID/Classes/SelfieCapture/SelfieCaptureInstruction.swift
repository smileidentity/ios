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
    case turnPhoneUp

    var instruction: String {
        switch self {
        case .headInFrame:
            return "Instructions.PositionHeadInView"
        case .moveCloser:
            return "Instructions.MoveCloser"
        case .moveBack:
            return "Instructions.MoveBack"
        case .lookStraight:
            return "Instructions.PositionHeadInView"
        case .goodLight:
            return "Instructions.Brightness"
        case .lookLeft:
            return "Instructions.TurnHeadLeft"
        case .lookRight:
            return "Instructions.TurnHeadRight"
        case .lookUp:
            return "Instructions.TurnHeadUp"
        case .turnPhoneUp:
            return "Instructions.TurnPhoneUp"
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
        case .turnPhoneUp:
            return .turnPhoneUp
        }
    }
}
