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
    func multipart(
        signature: String,
        timestamp: String,
        to path: PathType,
        with body: SmartSelfieRequest
    ) -> AnyPublisher<SmartSelfieResponse, Error>

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

    func multipart(
        signature: String,
        timestamp: String,
        to path: PathType,
        with body: SmartSelfieRequest
    ) -> AnyPublisher<SmartSelfieResponse, Error> {
        let boundary = generateBoundary()
        var headers: [HTTPHeader] = []
        headers.append(.contentType(value: "multipart/form-data; boundary=\(boundary)"))
        headers.append(.partnerID(value: SmileID.config.partnerId))
        headers.append(.requestSignature(value: signature))
        headers.append(.timestamp(value: timestamp))
        return createMultiPartRequest(
            url: path,
            method: .post,
            headers: headers,
            uploadData: createMultiPartRequest(
                with: body,
                boundary: boundary
            )
        )
        .flatMap(serviceClient.multipart)
        .eraseToAnyPublisher()
    }

    private func createMultiPartRequest(
        url: PathType,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        uploadData: Data
    ) -> AnyPublisher<RestRequest, Error> {
        let path = String(describing: url)
        guard var baseURL = baseURL?.absoluteString else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        if let range = baseURL.range(of: "/v1/", options: .backwards) {
            baseURL.removeSubrange(range)
        }

        guard let url = URL(string: baseURL)?.appendingPathComponent(path) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
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
        return UUID().uuidString
    }

    // swiftlint:disable line_length cyclomatic_complexity
    func createMultiPartRequest(
            with request: SmartSelfieRequest,
            boundary: String
        ) -> Data {
            let lineBreak = "\r\n"
            var body = Data()

            // Append parameters if available
            if let parameters = request.partnerParams {
                for (key, value) in parameters {
                    if let valueData = "\(value)\(lineBreak)".data(using: .utf8) {
                        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                        body.append(valueData)
                    }
                }
            }

            // Append userId if available
            if let userId = request.userId {
                if let valueData = "\(userId)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"user_id\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append callbackUrl if available
            if let callbackUrl = request.callbackUrl {
                if let valueData = "\(callbackUrl)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"callback_url\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append sandboxResult if available
            if let sandboxResult = request.sandboxResult {
                let sandboxResultString = "\(sandboxResult)"
                if let valueData = "\(sandboxResultString)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"sandbox_result\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append allowNewEnroll if available
            if let allowNewEnroll = request.allowNewEnroll {
                let allowNewEnrollString = "\(allowNewEnroll)"
                if let valueData = "\(allowNewEnrollString)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"allow_new_enroll\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append liveness media files
            for item in request.livenessImages {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\("liveness_images")\"; filename=\"\(item.filename)\"\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Type: \(item.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
                body.append(item.data)
                body.append(lineBreak.data(using: .utf8)!)
            }
            
            // Append selfie media file
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\("selfie_image")\"; filename=\"\(request.selfieImage.filename)\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: \(request.selfieImage.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(request.selfieImage.data)
            body.append(lineBreak.data(using: .utf8)!)

            // Append final boundary
            body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

            return body
        }

}
