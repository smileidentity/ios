import UIKit

public final class AppSettingsManager: AppSettingsProtocol {
  private let application: UIApplicationProtocol
  private let settingsURL: URL?

  public init(
    application: UIApplicationProtocol = UIApplication.shared,
    settingsURL: URL? = URL(string: UIApplication.openSettingsURLString)
  ) {
    self.application = application
    self.settingsURL = settingsURL
  }

  public var canOpenAppSettings: Bool {
    guard let url = settingsURL else { return false }
    return application.canOpenURL(url)
  }

  public func openAppSettings() {
    guard let url = settingsURL else { return }
    application.open(url, options: [:], completionHandler: nil)
  }
}
