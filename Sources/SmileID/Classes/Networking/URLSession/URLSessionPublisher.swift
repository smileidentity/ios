import Foundation
import Combine

protocol URLSessionPublisher {
    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

extension URLSession: URLSessionPublisher {
    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}

extension URLSession {
    func send(request: URLRequest) async throws -> (data: Data, response: URLResponse) {
        try await data(for: request)
    }
}
