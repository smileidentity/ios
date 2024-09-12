import Foundation

protocol RestServiceClient {
    func send<T: Decodable>(request: RestRequest) async throws -> T
    func multipart<T: Decodable>(request: RestRequest) async throws -> T
    func upload(request: RestRequest) async throws -> Data
}
