import Sentry

class SmileIDCrashReporting {
    static let shared: SmileIDCrashReporting = SmileIDCrashReporting()

    private let smileIDPackagePrefix = "com.smileidentity"
    private(set) var hub: SentryHub?

    private init() {}

    deinit {
        disable()
    }

    func enable() {
        // setup sentry options
        let options = Sentry.Options()
        options.dsn = ArkanaKeys.Global().sENTRY_DSN
        options.releaseName = SmileID.version
        options.enableCrashHandler = true
        options.debug = true
        options.tracesSampleRate = 1.0
        options.profilesSampleRate = 1.0

        // setup sentry scope
        let scope = Sentry.Scope()
        scope.setTag(value: SmileID.config.partnerId, key: "partner_id")
        let user = Sentry.User()
        user.userId = SmileID.config.partnerId
        scope.setUser(user)

        // setup sentry hub
        let sentryClient = SentryClient(options: options)
        self.hub = SentryHub(client: sentryClient, andScope: scope)
    }

    func disable() {
        hub?.getClient()?.options.enableCrashHandler = false
        hub?.close()
        hub = nil
    }
}
