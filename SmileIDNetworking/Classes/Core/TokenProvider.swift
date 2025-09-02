import Foundation

protocol TokenProvider {
  func token() async throws -> String
}
