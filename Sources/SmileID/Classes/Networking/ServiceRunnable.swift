import Combine
import Foundation

protocol ServiceRunnable {
    var serviceClient: RestServiceClient { get }
    associatedtype PathType: CustomStringConvertible
    var baseURL: URL? { get }

    /// POST service call to a particular path with a body.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    ///   - body: The contents of the body of the request.
    func post<T: Encodable, U: Decodable>(to path: PathType, with body: T) -> AnyPublisher<U, Error>

    /// Get service call to a particular path
    /// - Parameters:
    ///   - path: Endpoint to execute the GET call.
    func get<U: Decodable>(to path: PathType) -> AnyPublisher<U, Error>

    /// PUT service call to a particular path with a body.
    /// - Parameters:
    ///   - data: Data to be uploaded
    ///   - url: Endpoint to upload to
    ///   - restMethod: The rest method to be used (PUT, POST etc )
    func upload(data: Data,
                to url: String,
                with restMethod: RestMethod) -> AnyPublisher<UploadResponse, Error>
}

extension ServiceRunnable {
    var baseURL: URL? {
        if SmileID.useSandbox {
            return URL(string: SmileID.config.testLambdaUrl)
        }
        return URL(string: SmileID.config.prodLambdaUrl)
    }

    func post<T: Encodable, U: Decodable>(to path: PathType, with body: T) -> AnyPublisher<U, Error> {
        return createRestRequest(path: path,
                                 method: .post,
                                 headers: [.contentType(value: "application/json")],
                                 body: body)
            .flatMap(serviceClient.send)
            .eraseToAnyPublisher()
    }

    func get<U: Decodable>(to path: PathType) -> AnyPublisher<U, Error> {
        return createRestRequest(path: path,
                                 method: .get,
                                 headers: [.contentType(value: "application/json")])
            .flatMap(serviceClient.send)
            .eraseToAnyPublisher()
    }

    func upload(data: Data,
                to url: String,
                with restMethod: RestMethod) -> AnyPublisher<UploadResponse, Error> {
        return createUploadRequest(url: url,
                                   method: restMethod,
                                   headers: [.contentType(value: "application/zip")],
                                   uploadData: data)
            .flatMap { serviceClient.upload(request: $0) }
            .eraseToAnyPublisher()
    }

    private func createUploadRequest(url: String,
                                     method: RestMethod,
                                     headers: [HTTPHeader]? = nil,
                                     uploadData: Data,
                                     queryParameters _: [HTTPQueryParameters]? = nil)
                                     -> AnyPublisher<RestRequest, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        let request = RestRequest(url: url,
                                  method: method,
                                  headers: headers,
                                  body: uploadData)
        return Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func createRestRequest<T: Encodable>(path: PathType,
                                                 method: RestMethod,
                                                 headers: [HTTPHeader]? = nil,
                                                 queryParameters: [HTTPQueryParameters]? = nil,
                                                 body: T) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        do {
            let request = try RestRequest(url: url,
                                          method: method,
                                          headers: headers,
                                          queryParameters: queryParameters,
                                          body: body)
            return Just(request)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    private func createRestRequest(path: PathType,
                                   method: RestMethod,
                                   headers: [HTTPHeader]? = nil,
                                   queryParameters: [HTTPQueryParameters]? = nil) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        let request = RestRequest(url: url,
                                  method: method,
                                  headers: headers,
                                  queryParameters: queryParameters)
        return Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
