import Foundation

protocol ServiceRunnable {
    var serviceClient: RestServiceClient { get }
    associatedtype PathType: CustomStringConvertible
    var baseURL: URL? { get }

    /// POST service call to a particular path with a body.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    ///   - body: The contents of the body of the request.
    func post<T: Encodable, U: Decodable>(to path: PathType, with body: T) async throws -> U

    /// Get service call to a particular path
    /// - Parameters:
    ///   - path: Endpoint to execute the GET call.
    func get<U: Decodable>(to path: PathType) async throws -> U

    // POST service call to make a multipart request.
    /// - Parameters:
    ///   - path: Endpoint to execute the POST call.
    ///   - body: The contents of the body of the mulitpart request.
    func multipart(
        to path: PathType,
        signature: String,
        timestamp: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String?,
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?
    ) async throws -> SmartSelfieResponse

    /// PUT service call to a particular path with a body.
    /// - Parameters:
    ///   - data: Data to be uploaded
    ///   - url: Endpoint to upload to
    ///   - restMethod: The rest method to be used (PUT, POST etc )
    func upload(
        data: Data,
        to url: String,
        with restMethod: RestMethod
    ) async throws -> AsyncThrowingStream<UploadResponse, Error>
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
    ) async throws -> U {
        let request = try await createRestRequest(
            path: path,
            method: .post,
            headers: [.contentType(value: "application/json")],
            body: body
        )
        return try await serviceClient.send(request: request)
    }

    func get<U: Decodable>(to path: PathType) async throws -> U {
        let request = try createRestRequest(
            path: path,
            method: .get
        )
        return try await serviceClient.send(request: request)
    }

    func multipart(
        to path: PathType,
        signature: String,
        timestamp: String,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String? = nil,
        partnerParams: [String: String]? = nil,
        callbackUrl: String? = nil,
        sandboxResult: Int? = nil,
        allowNewEnroll: Bool? = nil
    ) async throws -> SmartSelfieResponse {
        let boundary = generateBoundary()
        var headers: [HTTPHeader] = []
        headers.append(.contentType(value: "multipart/form-data; boundary=\(boundary)"))
        headers.append(.partnerID(value: SmileID.config.partnerId))
        headers.append(.requestSignature(value: signature))
        headers.append(.timestamp(value: timestamp))
        headers.append(.sourceSDK(value: "iOS"))
        headers.append(.sourceSDKVersion(value: SmileID.version))
        let request = try await createMultiPartRequest(
            url: path,
            method: .post,
            headers: headers,
            uploadData: createMultiPartRequestData(
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                userId: userId,
                partnerParams: partnerParams,
                callbackUrl: callbackUrl?.nilIfEmpty(),
                sandboxResult: sandboxResult,
                allowNewEnroll: allowNewEnroll,
                boundary: boundary
            )
        )

        return try await serviceClient.multipart(request: request)
    }

    private func createMultiPartRequest(
        url: PathType,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        uploadData: Data
    ) async throws -> RestRequest {
        let path = String(describing: url)
        guard var baseURL = baseURL?.absoluteString else {
            throw URLError(.badURL)
        }

        if let range = baseURL.range(of: "/v1/", options: .backwards) {
            baseURL.removeSubrange(range)
        }

        guard let url = URL(string: baseURL)?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }

        let request = RestRequest(
            url: url,
            method: method,
            headers: headers,
            body: uploadData
        )
        return request
    }

    func upload(
        data: Data,
        to url: String,
        with restMethod: RestMethod
    ) async throws -> AsyncThrowingStream<UploadResponse, Error> {
        let uploadRequest = try await createUploadRequest(
            url: url,
            method: restMethod,
            headers: [.contentType(value: "application/zip")],
            uploadData: data
        )
        return try await serviceClient.upload(request: uploadRequest)
    }

    private func createUploadRequest(
        url: String,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        uploadData: Data,
        queryParameters _: [HTTPQueryParameters]? = nil
    ) async throws -> RestRequest {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        let request = RestRequest(
            url: url,
            method: method,
            headers: headers,
            body: uploadData
        )
        return request
    }

    private func createRestRequest<T: Encodable>(
        path: PathType,
        method: RestMethod,
        headers: [HTTPHeader]? = nil,
        queryParameters: [HTTPQueryParameters]? = nil,
        body: T
    ) async throws -> RestRequest {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }

        do {
            let request = try RestRequest(
                url: url,
                method: method,
                headers: headers,
                queryParameters: queryParameters,
                body: body
            )
            return request
        } catch {
            throw error
        }
    }

    private func createRestRequest(
        path: PathType,
        method: RestMethod,
        queryParameters: [HTTPQueryParameters]? = nil
    ) throws -> RestRequest {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }

        let request = RestRequest(
            url: url,
            method: method,
            queryParameters: queryParameters
        )
        return request
    }

    func generateBoundary() -> String {
        return UUID().uuidString
    }

    // swiftlint:disable line_length cyclomatic_complexity
    func createMultiPartRequestData(
            selfieImage: MultipartBody,
            livenessImages: [MultipartBody],
            userId: String?,
            partnerParams: [String: String]?,
            callbackUrl: String?,
            sandboxResult: Int?,
            allowNewEnroll: Bool?,
            boundary: String
        ) -> Data {
            let lineBreak = "\r\n"
            var body = Data()

            // Append parameters if available
            if let parameters = partnerParams {
                for (key, value) in parameters {
                    if let valueData = "\(value)\(lineBreak)".data(using: .utf8) {
                        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                        body.append(valueData)
                    }
                }
            }

            // Append userId if available
            if let userId = userId {
                if let valueData = "\(userId)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"user_id\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append callbackUrl if available
            if let callbackUrl = callbackUrl {
                if let valueData = "\(callbackUrl)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"callback_url\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append sandboxResult if available
            if let sandboxResult = sandboxResult {
                let sandboxResultString = "\(sandboxResult)"
                if let valueData = "\(sandboxResultString)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"sandbox_result\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append allowNewEnroll if available
            if let allowNewEnroll = allowNewEnroll {
                let allowNewEnrollString = "\(allowNewEnroll)"
                if let valueData = "\(allowNewEnrollString)\(lineBreak)".data(using: .utf8) {
                    body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"allow_new_enroll\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                    body.append(valueData)
                }
            }

            // Append liveness media files
            for item in livenessImages {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\("liveness_images")\"; filename=\"\(item.filename)\"\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Type: \(item.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
                body.append(item.data)
                body.append(lineBreak.data(using: .utf8)!)
            }
            
            // Append selfie media file
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\("selfie_image")\"; filename=\"\(selfieImage.filename)\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: \(selfieImage.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(selfieImage.data)
            body.append(lineBreak.data(using: .utf8)!)

            // Append final boundary
            body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

            return body
        }

}
