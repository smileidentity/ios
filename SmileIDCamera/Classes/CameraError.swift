import Foundation

public enum CameraError: Error {
  case captureDeviceUnavailable
  case configurationFailed
  case permissionDenied
  case metadataUnavailable
}
