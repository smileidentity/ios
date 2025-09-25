import Foundation

enum NetworkError: Error, LocalizedError {
  case requestBuildFailed(underlying: Error)
  case nonHTTPResponse
  case transport(URLError)
  case server(
    status: Int,
    code: String?,
    message: String?,
    data: Data
  )
  case decodingFailed(underlying: Error)
  case unknown

  var errorDescription: String? {
    switch self {
    case .requestBuildFailed(let error):
      return "Failed to build request: \(error.localizedDescription)"
    case .nonHTTPResponse:
      return "Response was not HTTPURLResponse"
    case .transport(let error):
      return "Transport error: \(error.localizedDescription)"
    case .server(let status, let code, let message, _):
      return "Server \(status): \(code ?? "-") \(message ?? "-")"
    case .decodingFailed(let error):
      return "Decoding failed: \(error.localizedDescription)"
    case .unknown:
      return "Unknown network error"
    }
  }
}
