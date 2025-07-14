import SmileID
import SwiftUI

class RootViewModel: ObservableObject {
  @Published private(set) var decodedConfig: Config?

  // This is set by the SettingsView
  @AppStorage("smileConfig") private var configJson = (
    UserDefaults.standard.string(forKey: "smileConfig") ?? ""
  )
  private let jsonDecoder = JSONDecoder()

  init() {
    // It is possible the app was built without a smile_config, so it may be null
    let builtInConfig = Bundle.main.url(forResource: "smile_config", withExtension: "json")
      .flatMap {
        try? jsonDecoder.decode(Config.self, from: Data(contentsOf: $0))
      }
    let configFromUserStorage = try? jsonDecoder.decode(
      Config.self,
      from: configJson.data(using: .utf8)!)

    // If a config was set at runtime (i.e. saved in UserStorage) prioritize that. Fallback to
    // the built-in config if not set. Otherwise, ask the user to set a config.
    decodedConfig = configFromUserStorage ?? builtInConfig
  }

  func updateConfig(config: Config) {
    decodedConfig = config
  }
}
