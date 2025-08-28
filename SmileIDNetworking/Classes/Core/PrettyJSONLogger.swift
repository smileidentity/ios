import Foundation

final class PrettyJSONLogger: NetworkLogger {
  init() {}

  func logRequest(
    _ request: URLRequest,
    redacted: Set<String>
  ) {
    var headers = request.allHTTPHeaderFields ?? [:]
    // redact sensitive headers (case-insensitive)
    for key in Array(headers.keys) {
      if redacted.contains(key.lowercased()) {
        headers[key] = "<redacted>"
      }
    }
    print("➡️ REQUEST \(request.httpMethod ?? ""): \(request.url?.absoluteString ?? "-")")
    print("Headers: \(headers)")
    if let body = request.httpBody {
      if let string = prettyJSONString(from: body) {
        print("Body as JSON:\n\(string)")
      } else {
        print("Body: <\(body.count) bytes>")
      }
    }
  }

  func logResponse(
    data: Data,
    response: HTTPURLResponse,
    redacted _: Set<String>
  ) {
    print("⬅️ RESPONSE: \(response.statusCode) for \(response.url?.absoluteString ?? "-")")
    if let pretty = prettyJSONString(from: data) {
      print(pretty)
    } else {
      print("<\(data.count) bytes")
    }
  }

  func logError(_ error: any Error, request _: URLRequest?) {
    print("X Error: \(error)")
  }

  private func prettyJSONString(from data: Data) -> String? {
    guard let object = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
    else { return nil }
    return String(data: pretty, encoding: .utf8)
  }
}
