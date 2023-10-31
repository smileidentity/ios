import Foundation

public struct Config: Codable {
    public var partnerId: String
    public var authToken: String
    public var prodUrl: String
    public var testUrl: String
    public var prodLambdaUrl: String
    public var testLambdaUrl: String

    public init(
        partnerId: String,
        authToken: String,
        prodUrl: String,
        testUrl: String,
        prodLambdaUrl: String,
        testLambdaUrl: String
    ) {
        self.partnerId = partnerId
        self.authToken = authToken
        self.prodUrl = prodUrl
        self.testUrl = testUrl
        self.prodLambdaUrl = prodLambdaUrl
        self.testLambdaUrl = testLambdaUrl
    }

    enum CodingKeys: String, CodingKey {
        case partnerId = "partner_id"
        case authToken = "auth_token"
        case prodUrl = "prod_url"
        case testUrl = "test_url"
        case prodLambdaUrl = "prod_lambda_url"
        case testLambdaUrl = "test_lambda_url"
    }
}
