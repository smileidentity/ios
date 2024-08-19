import SmileID
import SwiftUI

struct RootView: View {
    @StateObject var viewModel = RootViewModel()
    @State private var showSuccess = false
    @State private var partnerId: String?

    init() {
        UITabBar.appearance().barTintColor = UIColor(SmileID.theme.backgroundLight)
        UITabBar.appearance().tintColor = UIColor(SmileID.theme.accent)
    }

    var body: some View {
        if let decodedConfig = viewModel.decodedConfig, !showSuccess {
            TabView {
                HomeView(config: decodedConfig)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                JobsView(viewModel: JobsViewModel(config: decodedConfig))
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Jobs")
                    }
                ResourcesView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("Resources")
                    }
                SettingsView(
                    viewModel: SettingsViewModel(
                        didUpdateConfig: { viewModel.updateConfig(config: $0) }
                    )
                )
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .accentColor(SmileID.theme.accent)
            .background(SmileID.theme.backgroundLight.ignoresSafeArea())
            .ignoresSafeArea()
            .preferredColorScheme(.light)
        } else {
            WelcomeScreen(
                showSuccess: $showSuccess,
                didUpdateConfig: { viewModel.updateConfig(config: $0) }
            )
        }
    }
}

private struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
