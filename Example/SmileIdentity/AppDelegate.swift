import UIKit
import SmileID
import SwiftUI
import netfox
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        NFX.sharedInstance().start()
        do {
            let config = try Config(url: Constant.configUrl)
            SmileID.initialize(config: config)
        } catch {
            print(error.localizedDescription)
        }
        window?.rootViewController = UIHostingController(rootView: MainView())
        window?.makeKeyAndVisible()
        return true
    }
}