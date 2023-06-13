import Foundation
import Combine

protocol URLSessionPublisher {
    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

extension URLSession: URLSessionPublisher {
    func send(request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}
