import AVFoundation
import Foundation

public protocol CameraPermissionsProtocol {
  var hasCameraAccess: Bool { get }
  func authorizationStatus() -> AVAuthorizationStatus
  func requestAccess(
    queue: DispatchQueue,
    completion: @escaping (Bool?) -> Void
  )
}
