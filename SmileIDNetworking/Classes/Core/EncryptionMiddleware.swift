import Foundation

final class EncryptionMiddleware: HTTPClientMiddleware {
  let next: HTTPClientProtocol
  private let encryptor: Encryptor
  private let shouldEncrypt: (URLRequest) -> Bool

  init(
    next: HTTPClientProtocol,
    encryptor: Encryptor,
    shouldEncrypt: @escaping (URLRequest) -> Bool
  ) {
    self.next = next
    self.encryptor = encryptor
    self.shouldEncrypt = shouldEncrypt
  }

  func send(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse) {
    var req = request
    defer { removeInternalHints(&req) }
    if shouldEncrypt(req), let body = req.httpBody {
      let encrypted = try encryptor.encrypt(body)
      var payload = Data()
      payload.append(encrypted.iv)
      payload.append(encrypted.ciphertext)
      payload.append(encrypted.tag)
      req.httpBody = payload
      req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    }
    return try await next.send(req)
  }

  private func removeInternalHints(_ req: inout URLRequest) {
    req.setValue(nil, forHTTPHeaderField: InternalHeaders.needsEncryption)
  }
}
