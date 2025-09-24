import UIKit

public final class AppSettingsManager: AppSettingsProtocol {
  private let application: UIApplication = .shared
  private(set) lazy var settingsURL: URL? = URL(string: UIApplication.openSettingsURLString)

  public init() {}

  public var canOpenAppSettings: Bool {
    guard let url = settingsURL else { return false }
    return application.canOpenURL(url)
  }

  public func openAppSettings() {
    guard let url = settingsURL else { return }
    application.open(url, options: [:], completionHandler: nil)
  }
}
