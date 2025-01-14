import ArkanaKeys
import Sentry

protocol ErrorReportingService {
    func captureError(_ error: any Error, userInfo: [String: Any]?)
}

class SentryErrorReporter {
    static let shared: SentryErrorReporter = SentryErrorReporter()

    private var sentryHub: SentryHub?

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
        self.sentryHub = SentryHub(client: sentryClient, andScope: scope)
    }

    func disable() {
        sentryHub?.getClient()?.options.enableCrashHandler = false
        sentryHub?.close()
        sentryHub = nil
    }
}

extension SentryErrorReporter: ErrorReportingService {
    func captureError(_ error: any Error, userInfo: [String: Any]? = nil) {
        sentryHub?.capture(error: error)
    }
}
