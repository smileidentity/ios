import SwiftUI
import SmileID
@available(iOS 14.0, *)
struct MainView: View {

    init() {
        UITabBar.appearance().barTintColor = offWhiteUIColor
        if #available(iOS 14.0, *) {
            UITabBar.appearance().tintColor = UIColor(SmileID.theme.accent)
        } else {
            // Fallback on earlier versions
            UITabBar.appearance().tintColor = .blue
        }
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(name: "Georgia-Bold", size: 30)!]
    }

    var body: some View {

        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .edgesIgnoringSafeArea(.all)

            CountryListView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("Resources")
                }

            AboutUsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("About us")
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
