import Foundation
import UIKit

public class SmileIdentity {
    @Injected var injectedApi: SmileIdentityServiceable
    public static var api: SmileIdentityServiceable {
        return SmileIdentity.instance.injectedApi
    }
    public static var configuration: Config {
        return config
    }
    internal static let instance: SmileIdentity = {
        let container = DependencyContainer.shared
        container.register(SmileIdentityServiceable.self) {SmileIdentityService.init()}
        container.register(RestServiceClient.self) {URLSessionRestServiceClient.init()}
        container.register(ServiceHeaderProvider.self) {DefaultServiceHeaderProvider.init()}
        let instance = SmileIdentity()
        return instance
    }()
    private init() {}
    internal static var config: Config!
    internal static var useSandbox = true
    private (set) public static var theme: SmileIdTheme = DefaultTheme()

    public class func initialize(config: Config, useSandbox: Bool = true) {
        self.config = config
        self.useSandbox = useSandbox
        SmileIDResourcesHelper.registerFonts()
    }

    public class func apply(_ theme: SmileIdTheme) {
        self.theme = theme
    }

    public class func smartSelfieRegistrationScreen(userId: String = UUID().uuidString,
                                                    sessionId: String = "SID_Session",
                                                    delegate: SmartSelfieResultDelegate)
    -> SmartSelfieInstructionsView {
        let viewModel = SelfieCaptureViewModel(userId: userId, sessionId: sessionId, isEnroll: true)
        return  SmartSelfieInstructionsView(viewModel: viewModel, delegate: delegate)
    }

    public class func smartSelfieAuthenticationScreen(userId: String,
                                                      sessionId: String = "SID_ Session",
                                                      delegate: SmartSelfieResultDelegate)
    -> SmartSelfieInstructionsView {
        let viewModel = SelfieCaptureViewModel(userId: userId, sessionId: sessionId, isEnroll: false)
        return SmartSelfieInstructionsView(viewModel: viewModel, delegate: delegate)
    }

    public class func setEnvironment(useSandbox: Bool) {
        SmileIdentity.useSandbox = useSandbox
    }
}
