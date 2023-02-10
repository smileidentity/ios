import Foundation

public class SmileIdentity {
    public static var api: SmileIdentityServiceable {
        return instance.se
    }
    internal static var instance = SmileIdentity()
    private init() {
        let container = DependencyContainer.shared
        container.register(SmileIdentityServiceable.self) {SmileIdentityService.init()}
    }
    internal var apiKey: String?
    internal var config: Config?
    internal var useSandbox = false

    public class func initialize(apiKey: String, config: URL, useSandbox: Bool = false) throws {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: config)
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedConfig = try decoder.decode(Config.self, from: data)
            instance.config = decodedConfig
            instance.apiKey = apiKey
            instance.useSandbox = useSandbox
        } catch {
            throw error
        }
    }
}
