import Foundation

enum CaptureGuideAnimation {
    case goodLight
    case headInView
    case moveBack
    case moveCloser
    case lookRight
    case lookLeft
    case lookUp
    
    var fileName: String {
        switch self {
        case .goodLight:
            return "light_animation"
        case .headInView:
            return "positioning"
        case .moveBack:
            return "positioning"
        case .moveCloser:
            return "positioning"
        case .lookRight:
            return "liveness_guides"
        case .lookLeft:
            return "liveness_guides"
        case .lookUp:
            return "liveness_guides"
        }
    }

    var animationProgressRange: ClosedRange<CGFloat> {
        switch self {
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