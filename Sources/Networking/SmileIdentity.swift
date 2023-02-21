import Foundation
import UIKit

public class SmileIdentity {
    @Injected var injectedapi: SmileIdentityServiceable
    public static var api: SmileIdentityServiceable {
        return SmileIdentity.instance.injectedapi
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
    internal static var config: Config?
    internal static var useSandbox = true

    public class func initialize(config: Config, useSandbox: Bool = true) {
        self.config = config
        self.useSandbox = useSandbox
    }
}
