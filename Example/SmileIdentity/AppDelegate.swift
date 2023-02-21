import UIKit
import SmileIdentity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let configUrl = Bundle.main.url(forResource: "smile_config", withExtension: "json")
        do {
            let config = try Config(url: configUrl!)
            SmileIdentity.initialize(config: config)
        } catch {
            print(error.localizedDescription)
        }
        return true
    }
}
