import Foundation

// TODO: Change implementation to use auth_smile
struct AuthInterceptor {
  enum Scheme { case bearer(TokenProvider) }

  let scheme: Scheme

  init(scheme: Scheme) {
    self.scheme = scheme
  }

  func apply(to request: inout URLRequest) async throws {
    switch scheme {
    case .bearer(let provider):
      let token = try await provider.token()
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }
}

final class AuthMiddleware: HTTPClientMiddleware {
  let next: HTTPClientProtocol
  private let interceptor: AuthInterceptor?

  init(
    next: HTTPClientProtocol,
    interceptor: AuthInterceptor?
  ) {
    self.next = next
    self.interceptor = interceptor
  }

  func send(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse) {
    var req = request
    defer { removeInternalHints(&req) }
    if req.value(forHTTPHeaderField: InternalHeaders.needsAuth) != nil,
       let interceptor {
      try await interceptor.apply(to: &req)
    }
    return try await next.send(req)
  }

  private func removeInternalHints(_ req: inout URLRequest) {
    req.setValue(nil, forHTTPHeaderField: InternalHeaders.needsAuth)
  }
}

actor DefaultTokenProvider: TokenProvider {
  private var cached: String?
  private let fetch: () async throws -> String

  init(
    fetch: @escaping () async throws -> String
  ) {
    self.fetch = fetch
  }

  func token() async throws -> String {
    if let token = cached {
      return token
    }
    let new = try await fetch()
    cached = new
    return new
  }
}
