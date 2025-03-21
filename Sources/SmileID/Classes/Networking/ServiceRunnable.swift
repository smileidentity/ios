import Foundation
import SmileIDSecurity
import UIKit // todo remove after testing

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
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        metadata: Metadata
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
        metadata: Metadata = Metadata.default()
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

        let startDate = Date()
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
            metadata: metadata.items
        )
        do {
            let payload = try encoder.encode(selfieRequest)
            let requestMac = try SmileIDCryptoManager.shared.sign(
                timestamp: timestamp,
                headers: headers.toDictionary(),
                payload: payload
            )
            headers.append(.requestMac(value: requestMac))
        } catch { /* in case we can't add the security info the backend will deal with the enrollment */ }
        let endDate = Date()
        let time = endDate.timeIntervalSince(startDate)
        print("Time for payload signing: \(time)")

        DispatchQueue.main.async {
            let vc = UIApplication.getTopViewController()
            let alert = UIAlertController(title: "Payload Signing Timing", message: String(time), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            if let vc = vc {
                vc.present(alert, animated: true, completion: nil)
            }
        }

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
                failureReason: failureReason,
                metadata: metadata,
                boundary: boundary
            )
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
        var signedHeaders = headers
        do {
            let payload = try encoder.encode(body)
            if let header = headers.first(where: { $0.name == "SmileID-Request-Timestamp" }) {
                let requestMac = try SmileIDCryptoManager.shared.sign(
                    timestamp: header.value,
                    headers: headers.toDictionary(),
                    payload: payload
                )
                signedHeaders += [.requestMac(value: requestMac)]
            }
        } catch { /* in case we can't add the security info the backend will deal with the enrollment */ }

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
        do {
            if let header = headers.first(where: { $0.name == "SmileID-Request-Timestamp" }) {
                let requestMac = try SmileIDCryptoManager.shared.sign(
                    timestamp: header.value,
                    headers: headers.toDictionary()
                )
                signedHeaders += [.requestMac(value: requestMac)]
            }
        } catch { /* in case we can't add the security info the backend will deal with the enrollment */ }

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
    func createMultiPartRequestData(
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
        userId: String?,
        partnerParams: [String: String]?,
        callbackUrl: String?,
        sandboxResult: Int?,
        allowNewEnroll: Bool?,
        failureReason: FailureReason?,
        metadata: Metadata = Metadata.default(),
        boundary: String
    ) -> Data {
        let lineBreak = "\r\n"
        var body = Data()

        // Append parameters if available
        if let parameters = partnerParams {
            if let boundaryData = "--\(boundary)\(lineBreak)".data(using: .utf8),
                let dispositionData = "Content-Disposition: form-data; name=\"partner_params\"\(lineBreak)".data(
                    using: .utf8),
                let contentTypeData = "Content-Type: application/json\(lineBreak + lineBreak)".data(using: .utf8),
                let lineBreakData = lineBreak.data(using: .utf8) {
                body.append(boundaryData)
                body.append(dispositionData)
                body.append(contentTypeData)

                if let jsonData = try? JSONSerialization.data(
                    withJSONObject: parameters,
                    options: [.sortedKeys, .withoutEscapingSlashes]
                ) {
                    body.append(jsonData)
                    body.append(lineBreakData)
                }
            }
        }

        // Append userId if available
        if let userId = userId {
            if let valueData = "\(userId)\(lineBreak)".data(using: .utf8) {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"user_id\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                body.append(valueData)
            }
        }

        // Append callbackUrl if available
        if let callbackUrl = callbackUrl {
            if let valueData = "\(callbackUrl)\(lineBreak)".data(using: .utf8) {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"callback_url\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                body.append(valueData)
            }
        }

        // Append sandboxResult if available
        if let sandboxResult = sandboxResult {
            let sandboxResultString = "\(sandboxResult)"
            if let valueData = "\(sandboxResultString)\(lineBreak)".data(using: .utf8) {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"sandbox_result\"\(lineBreak + lineBreak)".data(
                        using: .utf8)!)
                body.append(valueData)
            }
        }

        // Append allowNewEnroll if available
        if let allowNewEnroll = allowNewEnroll {
            let allowNewEnrollString = "\(allowNewEnroll)"
            if let valueData = "\(allowNewEnrollString)\(lineBreak)".data(using: .utf8) {
                body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"allow_new_enroll\"\(lineBreak + lineBreak)".data(
                        using: .utf8)!)
                body.append(valueData)
            }
        }

        // Append metadata
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        if let metadataData = try? encoder.encode(metadata.items) {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"metadata\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: application/json\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(metadataData)
            body.append(lineBreak.data(using: .utf8)!)
        }

        // Append liveness media files
        for item in livenessImages {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"\("liveness_images")\"; filename=\"\(item.filename)\"\(lineBreak)"
                    .data(using: .utf8)!)
            body.append("Content-Type: \(item.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(item.data)
            body.append(lineBreak.data(using: .utf8)!)
        }

        // Append selfie media file
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\("selfie_image")\"; filename=\"\(selfieImage.filename)\"\(lineBreak)"
                .data(using: .utf8)!)
        body.append("Content-Type: \(selfieImage.mimeType)\(lineBreak + lineBreak)".data(using: .utf8)!)
        body.append(selfieImage.data)
        body.append(lineBreak.data(using: .utf8)!)

        // Append failure reason if available
        if let failureReason,
           let failureReasonData = try? encoder.encode(failureReason) {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"failure_reason\"\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Type: application/json\(lineBreak + lineBreak)".data(using: .utf8)!)
            body.append(failureReasonData)
            body.append(lineBreak.data(using: .utf8)!)
        }

        // Append final boundary
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }
}

extension UIApplication {
    class func getTopViewController(
        base: UIViewController? = UIWindow.current?.rootViewController
    ) -> UIViewController? {
        if let navController = base as? UINavigationController {
            return getTopViewController(base: navController.visibleViewController)
        } else if let tabController = base as? UITabBarController,
            let selected = tabController.selectedViewController
        {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}

extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        return nil
    }
}
