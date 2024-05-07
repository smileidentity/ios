import Foundation
import Combine

protocol RestServiceClient {
    func send<T: Decodable>(request: RestRequest) -> AnyPublisher<T, Error>
    func upload(request: RestRequest) -> AnyPublisher<UploadResponse, Error>
    func multipart<T: Decodable>(request: RestRequest) -> AnyPublisher<T, Error>
}
