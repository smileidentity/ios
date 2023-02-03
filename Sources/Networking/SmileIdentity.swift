import Foundation

public class SmileIdentity {
    @Injected var service: SmileIdentityService
    public var api: SmileIdentityService {
        return service
    }
    internal static var instance = SmileIdentity()
    private init() {}
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
