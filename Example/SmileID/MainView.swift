import SwiftUI
import SmileID

@available(iOS 14.0, *)
struct MainView: View {

    init() {
        UITabBar.appearance().barTintColor = offWhiteUIColor
        UITabBar.appearance().tintColor = UIColor(SmileID.theme.accent)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Georgia-Bold", size: 30)!,
        ]
    }

    var body: some View {
        TabView {
            HomeView().tabItem {
                Image(systemName: "house")
                Text("Home")
            }

            ResourcesView().tabItem {
                Image(systemName: "info.circle")
                Text("Resources")
            }
        }
            .accentColor(SmileID.theme.accent)
            .background(offWhite.edgesIgnoringSafeArea(.all))
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.light)
    }
}

@available(iOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
