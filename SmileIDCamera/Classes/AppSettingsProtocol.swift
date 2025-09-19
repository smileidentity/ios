import Foundation

public protocol AppSettingsProtocol {
  var canOpenAppSettings: Bool { get }
  func openAppSettings()
}
