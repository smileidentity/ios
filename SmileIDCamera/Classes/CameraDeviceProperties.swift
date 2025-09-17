import AVFoundation
import CoreMedia
import Foundation

public struct CameraDeviceProperties: Equatable {
  public let exposureDuration: CMTime
  public let deviceType: AVCaptureDevice.DeviceType
  public let isVirtualDevice: Bool?
  public let lensPosition: Float
  public let iso: Float
  public let isAdjustingFocus: Bool
}
