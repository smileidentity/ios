import AVFoundation
import Foundation

/// Manager for torch/flash functionality
public struct TorchManager {
  private let device: AVCaptureDevice?
  public var level: Float = 1.0

  public init(device: AVCaptureDevice) {
    self.device = device.hasTorch ? device : nil
  }

  public mutating func toggle() {
    guard let device else { return }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }

      if device.isTorchActive {
        device.torchMode = .off
      } else {
        let desiredLevel = min(level, AVCaptureDevice.maxAvailableTorchLevel)
        try device.setTorchModeOn(level: desiredLevel)
      }
    } catch {}
  }
}
