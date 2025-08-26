import Foundation

protocol Signer {
  func sign(_ data: Data) throws -> Data
}
