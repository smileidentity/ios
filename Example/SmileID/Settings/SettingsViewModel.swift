import SmileID
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published @MainActor var errorMessage: String?
    @Published @MainActor var showSheet = false

    private let jsonDecoder = JSONDecoder()

    var didUpdateConfig: (Config) -> Void

    init(didUpdateConfig: @escaping (Config) -> Void) {
        self.didUpdateConfig = didUpdateConfig
    }

    func onUpdateSmileConfigSelected() {
        DispatchQueue.main.async { self.showSheet = true }
    }

    func updateSmileConfig(_ configJson: String) {
        do {
            let updatedConfig = try jsonDecoder.decode(Config.self, from: configJson.data(using: .utf8)!)
            UserDefaults.standard.set(configJson, forKey: "smileConfig")
            DispatchQueue.main.async {
                self.errorMessage = nil
                self.showSheet = false
            }
            self.didUpdateConfig(updatedConfig)
        } catch {
            print("Error decoding new config: \(error)")
            DispatchQueue.main.async { self.errorMessage = "Invalid Config" }
        }
    }
}
