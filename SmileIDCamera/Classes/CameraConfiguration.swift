import AVFoundation
import CoreGraphics
import Foundation

public struct CameraConfiguration {
  public var initialOrientation: AVCaptureVideoOrientation
  public var initialPosition: CameraDevicePosition
  public var sessionPreset: AVCaptureSession.Preset
  public var outputSettings: [String: Any]
  public var focusMode: AVCaptureDevice.FocusMode?
  public var focusPoint: CGPoint?
  public var autoFocusRestriction: AVCaptureDevice.AutoFocusRangeRestriction

  public init(
    initialOrientation: AVCaptureVideoOrientation = .portrait,
    initialPosition: CameraDevicePosition = .back,
    sessionPreset: AVCaptureSession.Preset = .high,
    outputSettings: [String: Any] = [:],
    focusMode: AVCaptureDevice.FocusMode? = nil,
    focusPoint: CGPoint? = nil,
    autoFocusRestriction: AVCaptureDevice.AutoFocusRangeRestriction = .none
  ) {
    self.initialOrientation = initialOrientation
    self.initialPosition = initialPosition
    self.sessionPreset = sessionPreset
    self.outputSettings = outputSettings
    self.focusMode = focusMode
    self.focusPoint = focusPoint
    self.autoFocusRestriction = autoFocusRestriction
  }
}
