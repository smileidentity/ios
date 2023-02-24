import Foundation
import UIKit

public class SmileIdentity {
    @Injected var injectedApi: SmileIdentityServiceable
    public static var api: SmileIdentityServiceable {
        return SmileIdentity.instance.injectedApi
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

    public class func initialize(config: Config, useSandbox: Bool = true) {
        self.config = config
        self.useSandbox = useSandbox
    }

    public class func smartSelfieRegistrationScreen(userID: String = UUID().uuidString, sessionID: String = "SID_Session", delegate: SmartSelfieResult) -> SelfieCaptureView {
        let viewModel = SelfieCaptureViewModel(userId: userID, sessionId: sessionID)
        return  SelfieCaptureView(viewModel: viewModel, delegate: delegate)
    }
}
