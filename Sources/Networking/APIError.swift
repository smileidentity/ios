import Foundation

public enum SmileIDError: Error {
    case encode(EncodingError)
    case request(URLError)
    case decode(DecodingError)
    case unknown(String)
    case api(String, String)
    case httpError(Int, Data)
}

extension SmileIDError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encode(let error):
            return String(describing: error)
        case .request(let error):
            return String(describing: error)
        case .decode(let error):
            return String(describing: error)
        case .unknown(let message):
            return message
        case .httpError(let statusCode, let data):
            return "HTTP Error with status code \(statusCode) and \(String(describing: data))"
        case .api(_, let message):
            return message
        }
    }
}

public struct SmileIDErrorResponse: Decodable {
    var message: String
    var code: String

    enum CodingKeys: String, CodingKey {
        case message = "error"
        case code
    }
}
