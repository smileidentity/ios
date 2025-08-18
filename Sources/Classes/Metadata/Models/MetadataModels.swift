import Foundation

enum LivenessType: String, Codable {
  case headPose = "head_pose"
  case smile
}

enum DocumentImageOriginValue: String {
  case gallery
  case cameraAutoCapture = "camera_auto_capture"
  case cameraManualCapture = "camera_manual_capture"
  var value: String {
    rawValue
  }
}

enum CameraFacingValue: String, Codable {
  case frontCamera = "front_camera"
  case backCamera = "back_camera"
}

public enum WrapperSdkName: String {
  case flutter
  case reactNative = "react_native"
  case reactNativeExpo = "react_native_expo"
}

public enum Platform: String {
  case mac
  case simulator
  case iphone
}
