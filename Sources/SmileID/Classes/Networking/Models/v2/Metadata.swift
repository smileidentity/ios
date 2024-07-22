import Foundation

public class Metadata: Codable {
    let items: [Metadatum]

    init(items: [Metadatum]) {
        self.items = items
    }

    static func `default`() -> Metadata {
        Metadata(items: [
            .sdk,
            .sdkVersion,
            .deviceModel,
            .deviceOS,
            .fingerprint
        ])
    }
}

public enum Metadatum: Codable {
    case sdk
    case sdkVersion
    case deviceModel
    case deviceOS
    case fingerprint
    case selfieImageOrigin(facing: CameraFacingValue)
    case selfieCaptureDuration(duration: String)
    case documentFrontImageOrigin(origin: DocumentImageOriginValue)
    case documentBackImageOrigin(origin: DocumentImageOriginValue)
    case documentFrontCaptureRetries(retries: Int)
    case documentBackCaptureRetries(retries: Int)
    case documentFrontCaptureDuration(duration: String)
    case documentBackCaptureDuration(duration: String)

    var value: String {
        switch self {
        case .sdk:
            return "iOS"
        case .sdkVersion:
            return SmileID.version
        case .deviceModel:
            return UIDevice.current.deviceModel
        case .deviceOS:
            return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        case .fingerprint:
            return SmileID.fingerprint
        case let .selfieImageOrigin(facing):
            return facing.rawValue
        case let .selfieCaptureDuration(duration):
            return duration
        case let .documentFrontImageOrigin(origin):
            return origin.rawValue
        case let .documentBackImageOrigin(origin):
            return origin.rawValue
        case let .documentFrontCaptureRetries(retries):
            return String(retries)
        case let .documentBackCaptureRetries(retries):
            return String(retries)
        case let .documentFrontCaptureDuration(duration):
            return duration
        case let .documentBackCaptureDuration(duration):
            return duration

            enum CodingKeys: String, CodingKey {
                case name, value
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(value, forKey: .value)
                switch self {
                case .sdk:
                    try container.encode("sdk", forKey: .name)
                case .sdkVersion:
                    try container.encode("sdk_version", forKey: .name)
                case .deviceModel:
                    try container.encode("device_model", forKey: .name)
                case .deviceOS:
                    try container.encode("device_os", forKey: .name)
                case .fingerprint:
                    try container.encode("fingerprint", forKey: .name)
                case .selfieImageOrigin:
                    try container.encode("camera_facing", forKey: .name)
                case .selfieCaptureDuration:
                    try container.encode("selfie_capture_duration_ms", forKey: .name)
                case .documentFrontImageOrigin:
                    try container.encode("document_front_image_origin", forKey: .name)
                case .documentBackImageOrigin:
                    try container.encode("document_back_image_origin", forKey: .name)
                case .documentFrontCaptureRetries:
                    try container.encode("document_front_capture_retries", forKey: .name)
                case .documentBackCaptureRetries:
                    try container.encode("document_back_capture_retries", forKey: .name)
                case .documentFrontCaptureDuration:
                    try container.encode("document_front_capture_duration_ms", forKey: .name)
                case .documentBackCaptureDuration:
                    try container.encode("document_back_capture_duration_ms", forKey: .name)
                }
            }
        }
    }
}

public enum DocumentImageOriginValue: String, Codable {
    case gallery
    case cameraAutoCapture = "camera_auto_capture"
    case cameraManualCapture = "camera_manual_capture"
}

public enum CameraFacingValue: String, Codable {
    case frontCamera = "front_camera"
    case backCamera = "back_camera"
}

public extension UIDevice {
    var isSimulator: Bool {
        TARGET_OS_SIMULATOR != 0
    }

    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    var deviceModel: String {
        isSimulator ? "emulator" : modelName
    }
}
