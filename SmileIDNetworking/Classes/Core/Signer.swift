import CryptoKit
import Foundation

protocol Signer {
  func sign(_ data: Data) throws -> Data
}

// TODO: Replace with Signer from SmileIDSecurity Package
public final class HMACSHA256Signer: Signer {
  private let key: SymmetricKey
  public init(secret: Data) { self.key = SymmetricKey(data: secret) }
  public func sign(_ data: Data) throws -> Data {
    let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
    return Data(signature)
  }
}
