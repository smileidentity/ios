import SwiftUI

public enum CaptureKind: String, Hashable, Codable, Sendable {
  case documentFront
  case documentBack
  case selfie
}

public enum LivenessType: String, Hashable, Codable, Sendable {
  case smileDetection
  case headPose
}

public enum CaptureMode: String, Hashable, Codable, Sendable {
  case auto
  case manual
}

public enum NavigationDestination: Hashable, Codable, Sendable {
  case instructions
  case documentInfo
  case capture(CaptureKind)
  case preview(CaptureKind)
  case processing
  case done
}
