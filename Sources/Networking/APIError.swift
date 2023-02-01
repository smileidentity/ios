import Foundation

enum APIError: Error {
    case encode(EncodingError)
    case request(URLError)
    case decode(DecodingError)
    case unknown(String)
    case httpStatus(Int, Data)
}

extension APIError: CustomStringConvertible {

    var description: String {
        switch self {
        case .encode(let error):
            return String(describing: error)
        case .request(let error):
            return String(describing: error)
        case .decode(let error):
            return String(describing: error)
        case .unknown(let message):
            return message
        case .httpStatus(_, let data):
            guard let response = try? JSONDecoder().decode(HTTPErrorResponse.self, from: data) else {
                return String(describing: data)
            }

            return response.message
        }
    }
}

private struct HTTPErrorResponse: Decodable {
    // TO-DO: Get shape of error response sent by smile
    var message: String
}
