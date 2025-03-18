import Foundation

enum MetadataKey: String {
    case activeLivenessType = "active_liveness_type"
    case activeLivenessVersion = "active_liveness_version"
    case cameraName = "camera_name"
    case clientIP = "client_ip"
    case deviceModel = "device_model"
    case deviceOS = "device_os"
    case documentBackCaptureRetries = "document_back_capture_retries"
    case documentBackCaptureDuration = "document_back_capture_duration_ms"
    case documentBackImageOrigin = "document_back_image_origin"
    case documentFrontCaptureRetries = "document_front_capture_retries"
    case documentFrontCaptureDuration = "document_front_capture_duration_ms"
    case documentFrontImageOrigin = "document_front_image_origin"
    case fingerprint
    case networkConnection = "network_connection"
    case selfieCaptureDuration = "selfie_capture_duration_ms"
    case selfieImageOrigin = "selfie_image_origin"
    case sdk
    case sdkVersion = "sdk_version"
}

public struct Metadatum: Codable {
    let name: String
    let value: AnyCodable

    init<T: Codable>(key: MetadataKey, value: T) {
        self.name = key.rawValue
        self.value = AnyCodable(value)
    }

    enum CodingKeys: String, CodingKey {
        case name, value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.value, forKey: .value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(AnyCodable.self, forKey: .value)
    }
}
