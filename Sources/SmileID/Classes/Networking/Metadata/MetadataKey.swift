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
