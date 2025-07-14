import Sentry
import SmileIDSecurity
import UIKit

class SmileIDCrashReporting {
    private static let smileIDPackagePrefix = "com.smileidentity"
    static var hub: SentryHub?

    private init() {}

    static func enable() {
        let options = Sentry.Options()
        options.dsn = SmileIDSecurity.ArkanaKeys.Global().sENTRY_DSN
        options.releaseName = SmileID.version
        options.enableCrashHandler = true

        let scope = Sentry.Scope()
        scope.setTag(value: SmileID.config.partnerId, key: "partner_id")
        let user = Sentry.User()
        user.userId = SmileID.config.partnerId
        scope.setUser(user)
        scope.setTag(value: UIDevice.current.modelName, key: "model")
        scope.setTag(value: UIDevice.current.systemVersion, key: "os_version")
        scope.setTag(value: SmileID.version, key: "sdk_version")

        let sentryClient = SentryClient(options: options)
        hub = SentryHub(client: sentryClient, andScope: scope)
    }

    static func disable() {
        hub?.getClient()?.options.enableCrashHandler = false
        hub?.close()
        hub = nil
    }
}
