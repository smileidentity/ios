import netfox
import Sentry
import SmileID
import SwiftUI
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        if let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String {
            SentrySDK.start { options in
                options.dsn = dsn
                options.debug = true
                options.tracesSampleRate = 1.0
                options.profilesSampleRate = 1.0
            }
        }
        NFX.sharedInstance().start()

        // NOTE TO PARTNERS: Normally, you would call SmileID.initialize() here

        window?.rootViewController = UIHostingController(rootView: RootView())
        window?.makeKeyAndVisible()
        return true
    }
}
