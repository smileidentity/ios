import AVFoundation
import Foundation

public final class CameraPermissionsManager: CameraPermissionsProtocol {
  private let mediaType: AVMediaType

  public init(mediaType: AVMediaType) {
    self.mediaType = mediaType
  }

  public var hasCameraAccess: Bool {
    authorizationStatus() == .authorized
  }

  public func authorizationStatus() -> AVAuthorizationStatus {
    AVCaptureDevice.authorizationStatus(for: mediaType)
  }

  public func requestAccess(
    queue: DispatchQueue,
    completion: @escaping (Bool?) -> Void
  ) {
    let resume: (Bool?) -> Void = { granted in
      queue.async {
        completion(granted)
      }
    }

    switch authorizationStatus() {
    case .authorized:
      resume(true)
    case .denied, .restricted:
      resume(false)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        resume(granted)
      }
    @unknown default:
      resume(nil)
    }
  }
}
