import Foundation

public enum SmileIDError: Error {
    case encode(EncodingError)
    case request(URLError)
    case decode(DecodingError)
    case unknown(String)
    case api(String, String)
    case httpError(Int, String)
    case jobStatusTimeOut
    case consentDenied
    case invalidJobId
    case fileNotFound(String)
    case invalidRequestBody
    case operationCanceled(String)

    static func isNetworkFailure(
        error: SmileIDError
    ) -> Bool {
        guard case .request = error else { return false }
        return true
    }
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
            return "HTTP Error with status code \(statusCode) and \(data)"
        case .api(_, let message):
            return message
        case .jobStatusTimeOut:
            return "Job submitted successfully but polling job status timed out"
        case .consentDenied:
            return "Consent Denied"
        case .invalidJobId:
            return "Invalid jobId or not found"
        case .fileNotFound(let message):
            return message
        case .invalidRequestBody:
            return "Invalid request body. The request data is missing or empty."
        case let .operationCanceled(message):
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
