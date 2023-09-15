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
                                 method: .get)
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
}

extension SmileIDServiceable {
    /// Polls a particular endpoint
    /// - Parameters:
    ///   - service: The service where the request lives
    ///   - request: The request to be polled
    ///   - isComplete: A closure that returns a boolean when job complete is true
    ///   - interval: The time interval between polls
    ///   - numAttempts: The maximum number of attempst to be made
    public func poll<T: SmileIDServiceable, U: Decodable>(
        service: T,
        request: @escaping () -> AnyPublisher<U, Error>,
        isComplete: @escaping (U) -> Bool,
        interval: TimeInterval,
        numAttempts: Int
    ) -> AnyPublisher<U, Error> {
        var lastError: Error?
        var lastResponse: U?
        var attemptCount = 0

        let publisher = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: Error.self)
            .flatMap { _ -> AnyPublisher<U, Error> in
                attemptCount += 1
                return request()
            }
            .handleEvents(receiveOutput: { response in
                lastResponse = response
            })
            .catch { error -> AnyPublisher<U, Error> in
                lastError = error
                return Empty<U, Error>().eraseToAnyPublisher()
            }
            .first(where: { response in
                if isComplete(response) {
                    lastError = nil
                }
                return isComplete(response) || attemptCount >= numAttempts
            })
            .flatMap { response -> AnyPublisher<U, Error> in
                if attemptCount >= numAttempts {
                    if let lastResponse = lastResponse {
                        return Just(lastResponse).setFailureType(to: Error.self).eraseToAnyPublisher()
                    } else if let lastError = lastError {
                        return Fail(error: lastError).eraseToAnyPublisher()
                    }
                }
                return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()

        return publisher
    }
}
