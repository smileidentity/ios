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
                .requestTimestamp(value: Date().toISO8601WithMilliseconds())
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
                .requestTimestamp(value: Date().toISO8601WithMilliseconds())
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
        let boundary = generateBoundary()
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

        let uploadData: Data
        if enableEncryption {
            uploadData = try createEncryptedMultiPartRequestData(
                selfieRequest: selfieRequest,
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                boundary: boundary,
                timestamp: timestamp
            )
        } else {
            uploadData = createMultiPartRequestData(
                selfieRequest: selfieRequest,
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                boundary: boundary
            )
        }

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

    func generateBoundary() -> String {
        return UUID().uuidString
    }

    func createEncryptedMultiPartRequestData(
        selfieRequest: SelfieRequest,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        boundary: String,
        timestamp: String
    ) throws -> Data {
        // Plain Text Form Fields
        var formFields: [String: Any] = ["metadata": selfieRequest.metadata]
        if let partnerParams = selfieRequest.partnerParams {
            formFields["partner_params"] = partnerParams
        }
        if let userId = selfieRequest.userId {
            formFields["user_id"] = userId
        }
        if let callbackUrl = selfieRequest.callbackUrl {
            formFields["callback_url"] = callbackUrl
        }
        if let sandboxResult = selfieRequest.sandboxResult {
            formFields["sandbox_result"] = sandboxResult
        }
        if let allowNewEnroll = selfieRequest.allowNewEnroll {
            formFields["allow_new_enroll"] = allowNewEnroll
        }
        if let failureReason = selfieRequest.failureReason {
            formFields["failure_reason"] = failureReason
        }

        // Binary parts (liveness first to preserve ordering expected by backend.
        let plainBinaries = livenessImages.map(\.data) + [selfieImage.data]

        let (encryptedFields, encryptedBinaries) = try SmileIDCryptoManager.shared.encryptMultipartData(
            timestamp: timestamp,
            formFields: formFields,
            binaryData: plainBinaries
        )

        let encryptedLivenessImages = zip(livenessImages, encryptedBinaries.dropLast()).compactMap {
            MultipartBody(withImage: $1, forName: $0.filename)
        }

        guard let encryptedSelfie = MultipartBody(
            withImage: encryptedBinaries.last ?? selfieImage.data,
            forName: selfieImage.filename
        ) else {
            throw SmileIDCryptoError.encodingError
        }

        return createMultiPartRequestDataWithEncryption(
            selfieImage: encryptedSelfie,
            livenessImages: encryptedLivenessImages,
            encryptedFields: encryptedFields,
            boundary: boundary
        )
    }

    private func createMultiPartRequestDataWithEncryption(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        encryptedFields: [String: String],
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        // Encrypted form fields
        encryptedFields
            .sorted(by: { $0.key < $1.key })
            .forEach { key, value in
                appendStringField(
                    key,
                    value: value,
                    to: &body,
                    boundary: boundary,
                    lineBreak: lineBreak
                )
            }

        // Encrypted binary fields
        livenessImages.forEach { image in
            appendFileField(
                name: "liveness_images",
                file: image,
                to: &body,
                boundary: boundary,
                lineBreak: lineBreak
            )
        }

        appendFileField(
            name: "selfie_image",
            file: selfieImage,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        // Closing boundary
        body.appendUtf8("--\(boundary)--\(lineBreak)")
        return body
    }

    func createMultiPartRequestData(
        selfieRequest: SelfieRequest,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        // Text / Numeric Fields
        appendStringField(
            "user_id",
            value: selfieRequest.userId,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "callback_url",
            value: selfieRequest.callbackUrl,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "sandbox_result",
            value: selfieRequest.sandboxResult.map(String.init),
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "allow_new_enroll",
            value: selfieRequest.allowNewEnroll.map(String.init),
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        // JSON-encoded fields
        appendJSONField(
            "partner_params",
            encodable: selfieRequest.partnerParams,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendJSONField(
            "metadata",
            encodable: selfieRequest.metadata,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendJSONField(
            "failure_reason",
            encodable: selfieRequest.failureReason,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        // Binary media fields
        livenessImages.forEach { image in
            appendFileField(
                name: "liveness_images",
                file: image,
                to: &body,
                boundary: boundary,
                lineBreak: lineBreak
            )
        }

        appendFileField(
            name: "selfie_image",
            file: selfieImage,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        // Closing boundary
        body.appendUtf8("--\(boundary)--\(lineBreak)")
        return body
    }

    // MARK: Multipart helpers

    private func appendStringField(
        _ name: String,
        value: String?,
        to body: inout Data,
        boundary: String,
        lineBreak: String
    ) {
        guard let value = value else { return }
        body.appendUtf8("--\(boundary)\(lineBreak)")
        body.appendUtf8("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)")
        body.appendUtf8("\(value)\(lineBreak)")
    }

    /// Appends a JSON-encoded field to a multipart body.
    private func appendJSONField<T: Encodable>(
        _ name: String,
        encodable: T?,
        to body: inout Data,
        boundary: String,
        lineBreak: String
    ) {
        guard let encodable = encodable else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let jsonData = try? encoder.encode(encodable) else { return }

        body.appendUtf8("--\(boundary)\(lineBreak)")
        body.appendUtf8("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)")
        body.appendUtf8("Content-Type: application/json\(lineBreak + lineBreak)")
        body.append(jsonData)
        body.appendUtf8(lineBreak)
    }

    /// Appends a binary file field to a multipart body.
    private func appendFileField(
        name: String,
        file: MultipartBody,
        to body: inout Data,
        boundary: String,
        lineBreak: String
    ) {
        body.appendUtf8("--\(boundary)\(lineBreak)")
        body.appendUtf8("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\(lineBreak)")
        body.appendUtf8("Content-Type: \(file.mimeType)\(lineBreak + lineBreak)")
        body.append(file.data)
    }
}

// MARK: - Safe UTF-8 append

private extension Data {
    /// Appends UTF-8 bytes for `string`, asserting in debug if encoding fails.
    mutating func appendUtf8(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            assertionFailure("Failed UTF-8 encoding for: \(string)")
            return
        }
        append(data)
    }
}
