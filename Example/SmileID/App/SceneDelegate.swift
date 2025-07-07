import ArkanaKeys
import Foundation
import netfox
import Sentry
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        if enableSentry() {
            SentrySDK.start { options in
                options.dsn = ArkanaKeys.Global().sENTRY_DSN
                options.debug = true
                options.tracesSampleRate = 1.0
                options.profilesSampleRate = 1.0
            }
        }
        NFX.sharedInstance().start()

        // NOTE TO PARTNERS: Normally, you would call SmileID.initialize() here
        window.rootViewController = UIHostingController(rootView: RootView())
        window.makeKeyAndVisible()
        self.window = window
    }

    func enableSentry() -> Bool {
        guard let enableSentry = Bundle.main.object(forInfoDictionaryKey: "EnableSentry") as? String else {
            return false
        }
        return enableSentry == "YES"
    }
}
