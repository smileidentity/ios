import Foundation

protocol Encryptor {
  func encrypt(
    _ data: Data
  ) throws -> (ciphertext: Data, iv: Data, tag: Data)
}
