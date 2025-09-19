import AVFoundation
import UIKit

extension UIDeviceOrientation {
  var cameraVideoOrientation: AVCaptureVideoOrientation {
    switch self {
    case .landscapeLeft: return .landscapeRight
    case .landscapeRight: return .landscapeLeft
    case .portraitUpsideDown: return .portraitUpsideDown
    default: return .portrait
    }
  }
}
