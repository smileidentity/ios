import Foundation

enum LivenessType: String, Codable {
    case headPose = "head_pose"
    case smile = "smile"
}

enum DocumentImageOriginValue: String {
    case gallery
    case cameraAutoCapture = "camera_auto_capture"
    case cameraManualCapture = "camera_manual_capture"
    var value: String {
        return rawValue
    }
}

enum CameraFacingValue: String, Codable {
    case frontCamera = "front_camera"
    case backCamera = "back_camera"
}

public enum WrapperSdkName: String {
    case flutter = "flutter"
    case reactNative = "react_native"
}
