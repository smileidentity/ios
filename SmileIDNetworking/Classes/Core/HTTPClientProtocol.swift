import Foundation

protocol HTTPClientProtocol {
  func send(
    _ request: URLRequest
  ) async throws -> (Data, HTTPURLResponse)
}
