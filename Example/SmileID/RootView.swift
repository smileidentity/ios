import SwiftUI
import SmileID

struct RootView: View {
    // This is set by the SettingsView
    @AppStorage("smileConfig") private var configJson = (
        UserDefaults.standard.string(forKey: "smileConfig") ?? ""
    )
    private let jsonDecoder = JSONDecoder()

    init() {
        UITabBar.appearance().barTintColor = UIColor(SmileID.theme.backgroundLight)
        UITabBar.appearance().tintColor = UIColor(SmileID.theme.accent)
    }

    var body: some View {
        let configUrl = Bundle.main.url(forResource: "smile_config", withExtension: "json")!
        let builtInConfig = try? jsonDecoder.decode(Config.self, from: Data(contentsOf: configUrl))
        let configFromUserStorage = try? jsonDecoder.decode(
            Config.self,
            from: configJson.data(using: .utf8)!
        )

        // If a config was set at runtime (i.e. saved in UserStorage) prioritize that. Fallback to
        // the built-in config if not set. Otherwise, ask the user to set a config.
        let decodedConfig = configFromUserStorage ?? builtInConfig

        if let decodedConfig {
            TabView {
                HomeView(config: decodedConfig)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }

                ResourcesView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("Resources")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
                .accentColor(SmileID.theme.accent)
                .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)

        } else {
            OnboardingScreen()
        }
    }
}

private struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
