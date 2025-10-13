import Foundation

enum MetadataKey: String {
  case activeLivenessType = "active_liveness_type"
  case activeLivenessVersion = "active_liveness_version"
  case buildPlatform = "build_platform"
  case buildReceipt = "build_receipt"
  case cameraName = "camera_name"
  case clientIP = "client_ip"
  case deviceModel = "device_model"
  case deviceOrientation = "device_orientation"
  case deviceOS = "device_os"
  case deviceJailBroken = "device_jail_broken"
  case deviceMovementDetected = "device_movement_detected"
  case documentBackCaptureRetries = "document_back_capture_retries"
  case documentBackCaptureDuration = "document_back_capture_duration_ms"
  case documentBackImageOrigin = "document_back_image_origin"
  case documentFrontCaptureRetries = "document_front_capture_retries"
  case documentFrontCaptureDuration = "document_front_capture_duration_ms"
  case documentFrontImageOrigin = "document_front_image_origin"
  case fingerprint
  case geolocation
  case hostApplication = "host_application"
  case locale
  case localTimeOfEnrolment = "local_time_of_enrolment"
  case memoryInfo = "memory_info"
  case networkConnection = "network_connection"
  case networkRetries = "network_retries"
  case numberOfCameras = "number_of_cameras"
  case packageName = "package_name"
  case proxyDetected = "proxy"
  case proximitySensor = "proximity_sensor"
  case securityPolicyVersion = "security_policy_version"
  case screenResolution = "screen_resolution"
  case selfieCaptureDuration = "selfie_capture_duration_ms"
  case selfieImageOrigin = "selfie_image_origin"
  case selfieCaptureRetries = "selfie_capture_retries"
  case sdk
  case sdkVersion = "sdk_version"
  case sdkLaunchCount = "sdk_launch_count"
  case systemArchitecture = "system_architecture"
  case timezone
  case vpnDetected = "vpn"
  case wrapperName = "wrapper_name"
  case wrapperVersion = "wrapper_version"
}
