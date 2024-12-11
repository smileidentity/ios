import Foundation

enum CaptureGuideAnimation: Equatable {
    case goodLight
    case headInFrame
    case moveBack
    case moveCloser
    case lookRight
    case lookLeft
    case lookUp
    case turnPhoneUp

    var fileName: String {
        switch self {
        case .goodLight:
            return "light_animation_with_bg"
        case .headInFrame:
            return "positioning_with_bg"
        case .moveBack:
            return "positioning_with_bg"
        case .moveCloser:
            return "positioning_with_bg"
        case .lookRight:
            return "headdirection_with_bg"
        case .lookLeft:
            return "headdirection_with_bg"
        case .lookUp:
            return "headdirection_with_bg"
        case .turnPhoneUp:
            return "device_orientation"
        }
    }

    var animationProgressRange: ClosedRange<CGFloat> {
        switch self {
        case .headInFrame:
            return 0...0.28
        case .moveBack:
            return 0.38...0.67
        case .moveCloser:
            return 0.73...1.0
        case .lookRight:
            return 0...0.4
        case .lookLeft:
            return 0.4...0.64
        case .lookUp:
            return 0.64...1.0
        default:
            return 0...1.0
        }
    }
}
