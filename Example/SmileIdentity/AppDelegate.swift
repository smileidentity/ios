import UIKit
import SmileIdentity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = Bundle.main.url(forResource: "smile_config", withExtension: "json")
        try? SmileIdentity.initialize(apiKey: "test api key", config: config!)
        return true
    }
}
