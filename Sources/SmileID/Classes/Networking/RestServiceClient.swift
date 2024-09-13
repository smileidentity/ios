import Foundation

protocol RestServiceClient {
    func send<T: Decodable>(request: RestRequest) async throws -> T
    func multipart<T: Decodable>(request: RestRequest) async throws -> T
    /// Uploads the given `RestRequest` asynchronously and returns the response data.
    /// 
    /// - Parameter request: The `RestRequest` object containing the details of the request to be uploaded.
    /// - Returns: The response data from the server.
    /// - Throws: An error if the upload fails.
    func upload(request: RestRequest) async throws -> Data
}
