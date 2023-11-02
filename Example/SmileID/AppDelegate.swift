import UIKit
import SmileID
import SwiftUI
import netfox

@UIApplicationMain
@available(iOS 14.0, *)
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        NFX.sharedInstance().start()

        // NOTE TO PARTNERS: Normally, you would call SmileID.initialize() here

        window?.rootViewController = UIHostingController(rootView: MainView())
        window?.makeKeyAndVisible()
        return true
    }
}
