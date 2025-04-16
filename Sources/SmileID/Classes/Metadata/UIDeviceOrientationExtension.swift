import UIKit

extension UIDeviceOrientation {
    var category: String {
        switch self {
        case .portrait, .portraitUpsideDown:
            return "Portrait"
        case .landscapeLeft, .landscapeRight:
            return "Landscape"
        case .faceUp:
            return "FaceUp"
        case .faceDown:
            return "FaceDown"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}
