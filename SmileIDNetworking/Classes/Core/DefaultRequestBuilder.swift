import Foundation

final class DefaultRequestBuilder {
  private let jsonEncoder: JSONEncoder

  init(jsonEncoder: JSONEncoder) {
    self.jsonEncoder = jsonEncoder
    self.jsonEncoder.dateEncodingStrategy = .iso8601
  }

  func makeURLRequest(
    baseURL: URL,
    endpoint: some Endpoint,
    config: NetworkConfig
  ) throws -> URLRequest {
    var url = baseURL.appendingPathComponent(endpoint.path)
    if let query = endpoint.query,
       !query.isEmpty {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      components?.queryItems = query.map {
        URLQueryItem(name: $0.key, value: $0.value)
      }
      url = components?.url ?? url
    }

    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.timeoutInterval = config.requestTimeout
    request.cachePolicy = config.cachePolicy

    // Apply configured headers first, then endpoint overrides
    for (key, value) in config.additionalHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }

    if let headers = endpoint.headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    if let body = endpoint.body {
      switch body {
      case .json(let encodable):
        let data = try jsonEncoder.encode(AnyEncodable(encodable))
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      case .formURLEncoded(let params):
        let bodyString = params.map {
          "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)"
        }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
      case .multipart(let form):
        let boundary = form.boundary
        request.httpBody = form.buildBody()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      }
    }

    return request
  }
}

/// Helper to encode `Encodable` without concrete type at callsite.
private struct AnyEncodable: Encodable {
  private let encodeClosure: (Encoder) throws -> Void

  init(_ encodable: Encodable) {
    self.encodeClosure = encodable.encode
  }

  func encode(to encoder: Encoder) throws {
    try encodeClosure(encoder)
  }
}
