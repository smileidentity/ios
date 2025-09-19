import AVFoundation
import Foundation
import UIKit

public final class DeviceOrientationObserver: ObservableObject {
  @Published public private(set) var videoOrientation: AVCaptureVideoOrientation = .portrait

  private let notificationCenter: NotificationCenter
  private var token: NSObjectProtocol?

  public init(
    notificationCenter: NotificationCenter = .default
  ) {
    self.notificationCenter = notificationCenter
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    token = notificationCenter.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main,
      using: { [weak self] _ in
        guard let self else { return }
        self.videoOrientation = UIDevice.current.orientation.cameraVideoOrientation
      }
    )
  }

  deinit {
    if let token {
      notificationCenter.removeObserver(token)
    }
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
  }
}
