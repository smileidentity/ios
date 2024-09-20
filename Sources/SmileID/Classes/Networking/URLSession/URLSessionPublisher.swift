import Combine
import Foundation

protocol URLSessionPublisher {
  func send(request: URLRequest) async throws -> (data: Data, response: URLResponse)
}

extension URLSession: URLSessionPublisher {
  func send(request: URLRequest) async throws -> (data: Data, response: URLResponse) {
    try await data(for: request)
  }
}
