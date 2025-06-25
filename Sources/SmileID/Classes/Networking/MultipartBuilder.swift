import Foundation
import SmileIDSecurity

struct MultipartBuilder {
    let boundary: String
    private let lineBreak: String = "\r\n"

    func buildUnencrypted(
        selfieRequest: SelfieRequest,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody]
    ) -> Data {
        var body = Data()

        // Text & numeric fields
        appendStringField("user_id", value: selfieRequest.userId, to: &body)
        appendStringField("callback_url", value: selfieRequest.callbackUrl, to: &body)
        appendStringField(
            "sandbox_result",
            value: selfieRequest.sandboxResult.map(String.init),
            to: &body
        )
        appendStringField(
            "allow_new_enroll",
            value: selfieRequest.allowNewEnroll.map(String.init),
            to: &body
        )

        // JSON fields
        appendJSONField("partner_params", encodable: selfieRequest.partnerParams, to: &body)
        appendJSONField("metadata", encodable: selfieRequest.metadata, to: &body)
        appendJSONField("failure_reason", encodable: selfieRequest.failureReason, to: &body)

        // Binary parts
        livenessImages.forEach {
            appendFileField(name: "liveness_images", file: $0, to: &body)
        }
        appendFileField(name: "selfie_image", file: selfieImage, to: &body)

        body.appendUtf8("--\(boundary)--\(lineBreak)")
        return body
    }

    func buildEncrypted(
        selfieRequest: SelfieRequest,
        selfieImage: MultipartBody,
        livenessImages: [MultipartBody],
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

        let (encryptedFields, encryptedBinaries) = try SmileIDCryptoManager.shared
            .encryptMultipartData(
                timestamp: timestamp,
                formFields: formFields,
                binaryData: plainBinaries
            )

        let encryptedLivenessImages = zip(
            livenessImages,
            encryptedBinaries.dropLast()
        ).compactMap {
            MultipartBody(withImage: $1, forName: $0.filename)
        }

        guard let encryptedSelfie = MultipartBody(
            withImage: encryptedBinaries.last ?? selfieImage.data,
            forName: selfieImage.filename
        ) else {
            throw SmileIDCryptoError.encodingError
        }

        // Assemble multipart body.
        var body = Data()
        encryptedFields.sorted(by: { $0.key < $1.key }).forEach {
            appendStringField($0.key, value: $0.value, to: &body)
        }
        encryptedLivenessImages.forEach {
            appendFileField(name: "liveness_images", file: $0, to: &body)
        }
        appendFileField(name: "selfie_image", file: encryptedSelfie, to: &body)

        body.appendUtf8("--\(boundary)--\(lineBreak)")
        return body
    }

    // MARK: Internal helpers
    private func appendStringField(
        _ name: String,
        value: String?,
        to body: inout Data
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
        to body: inout Data
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
        to body: inout Data
    ) {
        body.appendUtf8("--\(boundary)\(lineBreak)")
        body.appendUtf8(
            "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(file.filename)\"\(lineBreak)"
        )
        body.appendUtf8("Content-Type: \(file.mimeType)\(lineBreak + lineBreak)")
        body.append(file.data)
    }
}
