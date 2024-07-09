import Foundation

public class Metadata: Codable {
    let items: [Metadatum]

    init(items: [Metadatum]) {
        self.items = items
    }

    static func `default`() -> Metadata {
        Metadata(items: [
            Metadatum.sdk,
            Metadatum.sdkVersion,
            Metadatum.deviceModel,
            Metadatum.deviceOS,
            Metadatum.fingerprint
        ])
    }
}

public enum Metadatum: Codable {
    case sdk
    case sdkVersion
    case deviceModel
    case deviceOS
    case fingerprint
    case cameraFacing(facing: CameraFacingValue)
    case selfieCaptureDuration(duration: String)
    case documentFrontImageOrigin(origin: DocumentImageOriginValue)
    case documentBackImageOrigin(origin: DocumentImageOriginValue)
    case documentFrontRetryCount(retryCount: Int)
    case documentBackRetryCount(retryCount: Int)
    case documentFrontCaptureDuration(duration: String)
    case documentBackCaptureDuration(duration: String)
    case documentFrontAutoCapture(autoCapture: Bool)
    case documentBackAutoCapture(autoCapture: Bool)

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
        case let .cameraFacing(facing):
            return facing.rawValue
        case let .selfieCaptureDuration(duration):
            return duration
        case let .documentFrontImageOrigin(origin):
            return origin.rawValue
        case let .documentBackImageOrigin(origin):
            return origin.rawValue
        case let .documentFrontRetryCount(retryCount: retryCount):
            return String(retryCount)
        case let .documentBackRetryCount(retryCount: retryCount):
            return String(retryCount)
        case let .documentFrontCaptureDuration(duration):
            return duration
        case let .documentBackCaptureDuration(duration):
            return duration
        case let .documentFrontAutoCapture(autoCapture: autoCapture):
            return String(autoCapture)
        case let .documentBackAutoCapture(autoCapture: autoCapture):
            return String(autoCapture)

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
                case .cameraFacing:
                    try container.encode("camera_facing", forKey: .name)
                case .selfieCaptureDuration:
                    try container.encode("selfie_capture_duration", forKey: .name)
                case .documentFrontImageOrigin:
                    try container.encode("document_front_image_origin", forKey: .name)
                case .documentBackImageOrigin:
                    try container.encode("document_back_image_origin", forKey: .name)
                case .documentFrontRetryCount:
                    try container.encode("document_front_retry_count", forKey: .name)
                case .documentBackRetryCount:
                    try container.encode("document_back_retry_count", forKey: .name)
                case .documentFrontCaptureDuration:
                    try container.encode("front_document_capture_duration", forKey: .name)
                case .documentBackCaptureDuration:
                    try container.encode("back_document_capture_duration", forKey: .name)
                case .documentFrontAutoCapture:
                    try container.encode("document_front_auto_capture", forKey: .name)
                case .documentBackAutoCapture:
                    try container.encode("document_back_auto_capture", forKey: .name)
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
    case front
    case back
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
