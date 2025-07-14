import Foundation
import SmileIDSecurity

struct MultipartBuilder {
    let boundary: String
    private let lineBreak: String = "\r\n"

    func buildMultipart(
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

    func buildEncryptedMultipart(from jsonObject: [String: Any]) -> Data {
        var body = Data()

        for (key, value) in jsonObject {
            if let base64String = value as? String {
                appendStringField(key, value: base64String, to: &body)
            }
        }

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
        body.appendUtf8(lineBreak)
    }

    /// Appends a binary field to a multipart body.
    private func appendBinaryField(
        name: String,
        data: Data,
        to body: inout Data
    ) {
        body.appendUtf8("--\(boundary)\(lineBreak)")
        body.appendUtf8("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)")
        body.appendUtf8("Content-Type: application/octet-stream\(lineBreak + lineBreak)")
        body.append(data)
        body.appendUtf8(lineBreak)
    }
}
