import Foundation

protocol KeyStore {
  func data(for key: String) throws -> Data
  func set(_ data: Data, for key: String) throws
}
