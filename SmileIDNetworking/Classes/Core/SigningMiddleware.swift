import Foundation

final class SigningMiddleware: HTTPClientMiddleware {
  let next: HTTPClientProtocol
  private let signer: Signer
  private let shouldSign: (URLRequest) -> Bool

  init(
    next: HTTPClientProtocol,
    signer: Signer,
    shouldSign: @escaping (URLRequest) -> Bool
  ) {
    self.next = next
    self.signer = signer
    self.shouldSign = shouldSign
  }

  func send(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse) {
    var req = request
    defer { removeInternalHints(&req) }
    if shouldSign(req),
       let body = req.httpBody {
      let signature = try signer.sign(body).base64EncodedString()
      req.setValue(signature, forHTTPHeaderField: "X-Signature")
    }
    return try await next.send(req)
  }

  private func removeInternalHints(_ req: inout URLRequest) {
    req.setValue(nil, forHTTPHeaderField: InternalHeaders.needsSignature)
  }
}
