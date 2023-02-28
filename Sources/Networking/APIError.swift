import Foundation

public enum APIError: Error {
    case encode(EncodingError)
    case request(URLError)
    case decode(DecodingError)
    case unknown(String)
    case httpStatus(Int, Data)
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encode(let error):
            return String(describing: error.localizedDescription)
        case .request(let error):
            return String(describing: error.localizedDescription)
        case .decode(let error):
            return String(describing: error.localizedDescription)
        case .unknown(let message):
            return message
        case .httpStatus(let code, let data):
            guard let response = try? JSONDecoder().decode(HTTPErrorResponse.self, from: data) else {
                print("Error code is \(code)")
                return String(describing: data)
            }
            return response.message
        }
    }
}

private struct HTTPErrorResponse: Decodable {
    var message: String
    var code: String

    enum CodingKeys: String, CodingKey {
        case message = "error"
        case code
    }
}
