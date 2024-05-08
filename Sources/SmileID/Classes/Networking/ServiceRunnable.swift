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

    // POST service call to make a multipart request.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    ///   - body: The contents of the body of the mulitpart request.
    func multipart<U: Decodable>(to path: PathType, with body: MultiPartRequest) -> AnyPublisher<U, Error>

    /// PUT service call to a particular path with a body.
    /// - Parameters:
    ///   - data: Data to be uploaded
    ///   - url: Endpoint to upload to
    ///   - restMethod: The rest method to be used (PUT, POST etc )
    func upload(
        data: Data,
        to url: String,
        with restMethod: RestMethod
    ) -> AnyPublisher<UploadResponse, Error>
}

extension ServiceRunnable {
    var baseURL: URL? {
        if SmileID.useSandbox {
            return URL(string: SmileID.config.testLambdaUrl)
        }
        return URL(string: SmileID.config.prodLambdaUrl)
    }

    func post<T: Encodable, U: Decodable>(
        to path: PathType,
        with body: T
    ) -> AnyPublisher<U, Error> {
        createRestRequest(
            path: path,
            method: .post,
            headers: [.contentType(value: "application/json")],
            body: body
        )
            .flatMap(serviceClient.send)
            .eraseToAnyPublisher()
    }

    func get<U: Decodable>(to path: PathType) -> AnyPublisher<U, Error> {
        createRestRequest(
            path: path,
            method: .get
        )
            .flatMap(serviceClient.send)
            .eraseToAnyPublisher()
    }

    func multipart<U: Decodable>(
        to path: PathType,
        with body: MultiPartRequest
    ) -> AnyPublisher<U, Error> {
        createRestRequest(
            path: path,
            method: .post,
            headers: [.contentType(value: "multipart/form-data; boundary=\(generateBoundary())")],
            body: createMultiPartREquest(with: body, boundary: generateBoundary())
        )
            .flatMap(serviceClient.send)
            .eraseToAnyPublisher()
    }

    func upload(
        data: Data,
        to url: String,
        with restMethod: RestMethod
    ) -> AnyPublisher<UploadResponse, Error> {
        createUploadRequest(
            url: url,
            method: restMethod,
            headers: [.contentType(value: "application/zip")],
            uploadData: data
        )
            .flatMap { serviceClient.upload(request: $0) }
            .eraseToAnyPublisher()
    }

    private func createUploadRequest(
        url: String,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        uploadData: Data,
        queryParameters _: [HTTPQueryParameters]? = nil
    ) -> AnyPublisher<RestRequest, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        let request = RestRequest(
            url: url,
            method: method,
            headers: headers,
            body: uploadData
        )
        return Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func createRestRequest<T: Encodable>(
        path: PathType,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        queryParameters: [HTTPQueryParameters]? = nil,
        body: T
    ) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        do {
            let request = try RestRequest(
                url: url,
                method: method,
                headers: headers,
                queryParameters: queryParameters,
                body: body
            )
            return Just(request)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func createRestRequest(
        path: PathType,
        method: RestMethod,
        queryParameters: [HTTPQueryParameters]? = nil
    ) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let request = RestRequest(
            url: url,
            method: method,
            queryParameters: queryParameters
        )
        return Just(request)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func generateBoundary() -> String {
        return ProcessInfo.processInfo.globallyUniqueString
    }

    func createMultiPartREquest(
        with request: MultiPartRequest,
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        if let parameters = request.multiPartParams {
            for (key, value) in parameters {
                if let valueData = "\(value + lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary + lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }
        }

        for item in request.multiPartMedia {
            body.append("--\(boundary + lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(item.key)\"; filename=\"\(item.filename)\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: \(item.mimeType + lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(item.data)
            body.append(lineBreak.data(using: .utf8)!)
        }

        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }
}
