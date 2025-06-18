import Sentry

class SmileIDCrashReporting {
    private static let smileIDPackagePrefix = "com.smileidentity"
    static var hub: SentryHub?
    
    private static let TAG_MODEL = "model"
    private static let TAG_OS_VERSION = "os_version"
    private static let TAG_SDK_VERSION = "sdk_version"

    private init() {}

    static func enable() {
        let options = Sentry.Options()
        options.dsn = ArkanaKeys.Global().sENTRY_DSN
        options.releaseName = SmileID.version
        options.enableCrashHandler = true
        options.debug = true
        options.tracesSampleRate = 1.0
        options.profilesSampleRate = 1.0

        let scope = Sentry.Scope()
        scope.setTag(value: SmileID.config.partnerId, key: "partner_id")
        let user = Sentry.User()
        user.userId = SmileID.config.partnerId
        scope.setUser(user)
        scope.setTag(value: UIDevice.current.modelName, key: TAG_MODEL)
        scope.setTag(value: UIDevice.current.systemVersion, key: TAG_OS_VERSION)
        scope.setTag(value: SmileID.version, key: TAG_SDK_VERSION)

        let sentryClient = SentryClient(options: options)
        hub = SentryHub(client: sentryClient, andScope: scope)
    }

    static func disable() {
        hub?.getClient()?.options.enableCrashHandler = false
        hub?.close()
        hub = nil
    }
}
