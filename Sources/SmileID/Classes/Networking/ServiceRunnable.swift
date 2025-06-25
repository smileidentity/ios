import Foundation
import SmileIDSecurity

protocol ServiceRunnable {
    var serviceClient: RestServiceClient { get }
    var metadata: Metadata { get }
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
    ///   - enableEncryption: Whether to encrypt the multipart payload.
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
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        enableEncryption: Bool
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
    ) async throws -> Data
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
            headers: [
                .contentType(value: "application/json"),
                .partnerID(value: SmileID.config.partnerId),
                .sourceSDK(value: "iOS"),
                .sourceSDKVersion(value: SmileID.version),
                .requestTimestamp(value: Date().toISO8601WithMilliseconds()),
            ],
            body: body
        )
        return try await serviceClient.send(request: request)
    }

    func get<U: Decodable>(to path: PathType) async throws -> U {
        let request = try createRestRequest(
            path: path,
            method: .get,
            headers: [
                .partnerID(value: SmileID.config.partnerId),
                .sourceSDK(value: "iOS"),
                .sourceSDKVersion(value: SmileID.version),
                .requestTimestamp(value: Date().toISO8601WithMilliseconds()),
            ]
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
        allowNewEnroll: Bool? = nil,
        failureReason: FailureReason? = nil,
        enableEncryption: Bool = false
    ) async throws -> SmartSelfieResponse {
        let boundary = UUID().uuidString
        var headers: [HTTPHeader] = []
        headers.append(.contentType(value: "multipart/form-data; boundary=\(boundary)"))
        headers.append(.partnerID(value: SmileID.config.partnerId))
        headers.append(.requestSignature(value: signature))
        headers.append(.timestamp(value: timestamp))
        headers.append(.sourceSDK(value: "iOS"))
        headers.append(.sourceSDKVersion(value: SmileID.version))
        let timestamp = Date().toISO8601WithMilliseconds()
        headers.append(.requestTimestamp(value: timestamp))

        let metadata = metadata.collectAllMetadata()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let selfieRequest = SelfieRequest(
            selfieImage: selfieImage.data,
            livenessImages: livenessImages.map { $0.data },
            userId: userId,
            partnerParams: partnerParams,
            callbackUrl: callbackUrl?.nilIfEmpty(),
            sandboxResult: sandboxResult,
            allowNewEnroll: allowNewEnroll,
            failureReason: failureReason,
            metadata: metadata
        )

        let payload = try encoder.encode(selfieRequest)
        let requestMac = try? SmileIDCryptoManager.shared.sign(
            timestamp: timestamp,
            headers: headers.toDictionary(),
            payload: payload
        )
        if let requestMac = requestMac {
            headers.append(.requestMac(value: requestMac))
        } else {
            /*
             In case we can't add the security info the backend will throw an unauthorized error.
             In the future, we will handle this more gracefully once sentry integration has been implemented.
             */
        }
        
        let builder = MultipartBuilder(boundary: boundary)
        let uploadData = enableEncryption ? try builder.buildEncrypted(
            selfieRequest: selfieRequest,
            selfieImage: selfieImage,
            livenessImages: livenessImages,
            timestamp: timestamp
        ) : builder.buildUnencrypted(
            selfieRequest: selfieRequest,
            selfieImage: selfieImage,
            livenessImages: livenessImages
        )

        let request = try await createMultiPartRequest(
            url: path,
            method: .post,
            headers: headers,
            uploadData: uploadData
        )

        return try await serviceClient.multipart(request: request)
    }

    private func createMultiPartRequest(
        url: PathType,
        method: RestMethod,
        headers: [HTTPHeader],
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
    ) async throws -> Data {
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
        headers: [HTTPHeader],
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
        headers: [HTTPHeader],
        queryParameters: [HTTPQueryParameters]? = nil,
        body: T
    ) async throws -> RestRequest {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let payload = try encoder.encode(body)

        var signedHeaders = headers
        if let header = headers.first(where: { $0.name == "SmileID-Request-Timestamp" }) {
            let requestMac = try? SmileIDCryptoManager.shared.sign(
                timestamp: header.value,
                headers: headers.toDictionary(),
                payload: payload
            )
            if let requestMac = requestMac {
                signedHeaders.append(.requestMac(value: requestMac))
            } else {
                /*
                 In case we can't add the security info the backend will throw an unauthorized error.
                 In the future, we will handle this more gracefully once sentry integration has been implemented.
                 */
            }

            if path.contains("id_verification") {
                let (encryptedHeaders, encryptedPayload) = try SmileIDCryptoManager.shared.encrypt(
                    timestamp: header.value,
                    headers: signedHeaders.toDictionary(),
                    payload: payload
                )
                for index in 0..<signedHeaders.count {
                    let key = signedHeaders[index].name
                    if let encryptedValue = encryptedHeaders[key.lowercased()] as? String {
                        signedHeaders[index].value = encryptedValue
                    }
                }
                let request = RestRequest(
                    url: url,
                    method: method,
                    headers: signedHeaders,
                    queryParameters: queryParameters,
                    body: encryptedPayload!
                )
                return request
            }
        }

        do {
            let request = try RestRequest(
                url: url,
                method: method,
                headers: signedHeaders,
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
        headers: [HTTPHeader],
        queryParameters: [HTTPQueryParameters]? = nil
    ) throws -> RestRequest {
        let path = String(describing: path)
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw URLError(.badURL)
        }

        var signedHeaders = headers
        if let header = headers.first(where: { $0.name == "SmileID-Request-Timestamp" }) {
            let requestMac = try? SmileIDCryptoManager.shared.sign(
                timestamp: header.value,
                headers: headers.toDictionary()
            )
            if let requestMac = requestMac {
                signedHeaders.append(.requestMac(value: requestMac))
            } else {
                /*
                 In case we can't add the security info the backend will throw an unauthorized error.
                 In the future, we will handle this more gracefully once sentry integration has been implemented.
                 */
            }
        }
        let request = RestRequest(
            url: url,
            method: method,
            headers: signedHeaders,
            queryParameters: queryParameters
        )
        return request
    }
}
