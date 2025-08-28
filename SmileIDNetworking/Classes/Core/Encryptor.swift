import CryptoKit
import Foundation

protocol Encryptor {
  func encrypt(
    _ data: Data
  ) throws -> (ciphertext: Data, iv: Data, tag: Data)
}

// TODO: Replace with encryptor from SmileIDSecurity Package.
public final class AESGCMEncryptor: Encryptor {
  private let key: SymmetricKey
  public init(key: Data) { self.key = SymmetricKey(data: key) }
  public func encrypt(_ data: Data) throws -> (ciphertext: Data, iv: Data, tag: Data) {
    let nonce = try AES.GCM.Nonce()
    let sealed = try AES.GCM.seal(data, using: key, nonce: nonce)
    return (sealed.ciphertext, Data(nonce), sealed.tag)
  }
}
