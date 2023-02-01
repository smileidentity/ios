import Foundation

public struct Config: Decodable {
    var partnerId: String
    var authToken: String
    var prodLambdaURL: String
    var testLambdaURL: String
}
