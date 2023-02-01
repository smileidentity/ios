import Foundation
import Combine

protocol ServiceRunnable {
    var serviceClient: RestServiceClient { get }
    associatedtype PathType: CustomStringConvertible
    var baseURL: URL? { get }

    /// POST service call to a particular path with a body.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    ///   - body: The contents of the body of the request.
    func post<T: Encodable, U: Decodable>(to path: PathType, with body: T) -> AnyPublisher<U, Error>

    /// POST service call to a particular path without a body.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    func post<T: Decodable>(to path: PathType) -> AnyPublisher<T, Error>
}

extension ServiceRunnable {

    var baseURL: URL? {
        if SmileIdentity.instance.useSandbox {
            return URL(string: SmileIdentity.instance.config?.testLambdaURL ?? "")
        }
        return URL(string: SmileIdentity.instance.config?.prodLambdaURL ?? "")

    }

    func post<T: Encodable, U: Decodable>(to path: PathType, with body: T) -> AnyPublisher<U, Error> {
        return createRestRequest(path: path,
                                 method: .post,
                                 body: body)
        .flatMap(serviceClient.send)
        .eraseToAnyPublisher()
    }

    func post<T: Decodable>(to path: PathType) -> AnyPublisher<T, Error> {
        return createRestRequest(path: path,
                                 method: .post)
        .flatMap(serviceClient.send)
        .eraseToAnyPublisher()
    }

    private func createRestRequest(path: PathType,
                                   method: RestMethod,
                                   queryParameters: [HTTPQueryParameters]? = nil) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        let request = RestRequest(url: url,
                                  method: method,
                                  queryParameters: queryParameters)
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
}
