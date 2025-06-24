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
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                userId: userId,
                partnerParams: partnerParams,
                callbackUrl: callbackUrl?.nilIfEmpty(),
                sandboxResult: sandboxResult,
                allowNewEnroll: allowNewEnroll,
                failureReason: failureReason,
                metadata: metadata,
                boundary: boundary,
                timestamp: timestamp
            )
        } else {
            uploadData = createMultiPartRequestData(
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                userId: userId,
                partnerParams: partnerParams,
                callbackUrl: callbackUrl?.nilIfEmpty(),
                sandboxResult: sandboxResult,
                allowNewEnroll: allowNewEnroll,
                failureReason: failureReason,
                metadata: metadata,
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

    // swiftlint:disable line_length cyclomatic_complexity
    func createEncryptedMultiPartRequestData(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String?,
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        metadata: [Metadatum],
        boundary: String,
        timestamp: String
    ) throws -> Data {
        // Prepare form fields for encryption
        var formFields: [String: Any] = [:]

        if let partnerParams = partnerParams {
            formFields["partner_params"] = partnerParams
        }
        if let userId = userId {
            formFields["user_id"] = userId
        }
        if let callbackUrl = callbackUrl {
            formFields["callback_url"] = callbackUrl
        }
        if let sandboxResult = sandboxResult {
            formFields["sandbox_result"] = sandboxResult
        }
        if let allowNewEnroll = allowNewEnroll {
            formFields["allow_new_enroll"] = allowNewEnroll
        }
        if let failureReason = failureReason {
            formFields["failure_reason"] = failureReason
        }
        formFields["metadata"] = metadata

        // Prepare binary data for encryption
        var binaryData: [Data] = []
        for livenessImage in livenessImages {
            binaryData.append(livenessImage.data)
        }
        binaryData.append(selfieImage.data)

        // Encrypt the data
        let (encryptedFields, encryptedBinaryData) = try SmileIDCryptoManager.shared.encryptMultipartData(
            timestamp: timestamp,
            formFields: formFields,
            binaryData: binaryData
        )

        // Build multipart data with encrypted values
        guard
            let encryptedSelfie = MultipartBody(
                withImage: encryptedBinaryData.last ?? selfieImage.data,
                forName: selfieImage.filename
            )
        else {
            throw SmileIDCryptoError.encodingError
        }

        let encryptedLivenessImages = zip(livenessImages, encryptedBinaryData.dropLast())
            .compactMap { original, encrypted in
            MultipartBody(withImage: encrypted, forName: original.filename)
        }

        return createMultiPartRequestDataWithEncryption(
            selfieImage: encryptedSelfie,
            livenessImages: encryptedLivenessImages,
            encryptedFields: encryptedFields,
            boundary: boundary
        )
    }

    func createMultiPartRequestData(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String?,
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        metadata: [Metadatum],
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        // Text / Numeric Fields
        appendStringField(
            "user_id",
            value: userId,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "callback_url",
            value: callbackUrl,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "sandbox_result",
            value: sandboxResult.map(String.init),
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendStringField(
            "allow_new_enroll",
            value: allowNewEnroll.map(String.init),
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        // JSON-encoded fields
        appendJSONField(
            "partner_params",
            encodable: partnerParams,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendJSONField(
            "metadata",
            encodable: metadata,
            to: &body,
            boundary: boundary,
            lineBreak: lineBreak
        )

        appendJSONField(
            "failure_reason",
            encodable: failureReason,
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
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
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
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
        body.append("\(value)\(lineBreak)".data(using: .utf8)!)
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

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: application/json\(lineBreak + lineBreak)".data(using: .utf8)!)
        body.append(jsonData)
        body.append(lineBreak.data(using: .utf8)!)
    }

    /// Appends a binary file field to a multipart body.
    private func appendFileField(
        name: String,
        file: MultipartBody,
        to body: inout Data,
        boundary: String,
        lineBreak: String
    ) {
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(file.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
        body.append(file.data)
    }

    private func createMultiPartRequestDataWithEncryption(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        encryptedFields: [String: String],
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        // Append encrypted form fields
        for (key, encryptedValue) in encryptedFields.sorted(by: { $0.key < $1.key }) {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)

            if key == "partner_params" || key == "metadata" || key == "failure_reason" {
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Type: application/json\(lineBreak + lineBreak)".data(using: .utf8)!)
            } else {
                body.append(
                    "Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!
                )
            }

            body.append(encryptedValue.data(using: .utf8)!)
            body.append(lineBreak.data(using: .utf8)!)
        }

        // Append encrypted liveness media files
        for item in livenessImages {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"liveness_images\"; filename=\"\(item.filename)\"\(lineBreak)"
                    .data(using: .utf8)!
            )
            body.append(
                "Content-Type: \(item.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!
            )
            body.append(item.data)
            body.append(lineBreak.data(using: .utf8)!)
        }

        // Append encrypted selfie media file
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"selfie_image\"; filename=\"\(selfieImage.filename)\"\(lineBreak)"
                .data(using: .utf8)!
        )
        body.append(
            "Content-Type: \(selfieImage.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!
        )
        body.append(selfieImage.data)
        body.append(lineBreak.data(using: .utf8)!)

        // Append final boundary
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }
}
