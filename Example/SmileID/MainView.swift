import SwiftUI
import SmileID

@available(iOS 14.0, *)
struct MainView: View {

    init() {
        UITabBar.appearance().barTintColor = UIColor(SmileID.theme.backgroundLight)
        UITabBar.appearance().tintColor = UIColor(SmileID.theme.accent)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Epilogue-Bold", size: 30)!
        ]
    }

    var body: some View {
        TabView {
            HomeView()
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
    }
}

@available(iOS 14.0, *)
private struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
