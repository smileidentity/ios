import Foundation

public struct Config: Decodable {
    public var partnerId: String
    public var authToken: String
    public var prodUrl: String
    public var testUrl: String
    public var prodLambdaUrl: String
    public var testLambdaUrl: String
}

public extension Config {
    init(url: URL) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Data(contentsOf: url)
        let decodedConfig = try decoder.decode(Config.self, from: data)
        self.partnerId = decodedConfig.partnerId
        self.authToken = decodedConfig.authToken
        self.prodUrl = decodedConfig.prodUrl
        self.testUrl = decodedConfig.testUrl
        self.prodLambdaUrl = decodedConfig.prodLambdaUrl
        self.testLambdaUrl = decodedConfig.testLambdaUrl
    }
}
