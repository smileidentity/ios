import Foundation
import Combine

protocol RestServiceClient {
    func send<T: Decodable>(request: RestRequest) -> AnyPublisher<T, Error>
}
