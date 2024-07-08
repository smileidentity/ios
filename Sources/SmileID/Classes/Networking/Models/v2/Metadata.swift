import Foundation

public class Metadata: Codable {
    let items: [Metadatum]

    init(items: [Metadatum]) {
        self.items = items
    }

    static func `default`() -> Metadata {
        Metadata(items: [Metadatum.sdk, Metadatum.sdkVersion, Metadatum.fingerprint])
    }
}

public enum Metadatum: Codable {
    case sdk
    case sdkVersion
    case fingerprint
    case documentFrontImageOrigin(origin: DocumentImageOriginValue)
    case documentBackImageOrigin(origin: DocumentImageOriginValue)
    case cameraFacing(facing: CameraFacingValue)
    case documentFrontRetryCount(retryCount: Int)
    case documentBackRetryCount(retryCount: Int)
    case documentFrontAutoCapture(autoCapture: Bool)
    case documentBackAutoCapture(autoCapture: Bool)

    var value: String {
        switch self {
        case .sdk:
            return "iOS"
        case .sdkVersion:
            return SmileID.version
        case .fingerprint:
            return "iOS"
        case let .documentFrontImageOrigin(origin):
            return origin.rawValue
        case let .documentBackImageOrigin(origin):
            return origin.rawValue
        case let .cameraFacing(facing):
            return facing.rawValue
        case .documentFrontRetryCount(retryCount: let retryCount):
            return String(retryCount)
        case .documentBackRetryCount(retryCount: let retryCount):
            return String(retryCount)
        case .documentFrontAutoCapture(autoCapture: let autoCapture):
            return String(autoCapture)
        case .documentBackAutoCapture(autoCapture: let autoCapture):
            return String(autoCapture)
        }
        
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
            case .fingerprint:
                try container.encode("fingerprint", forKey: .name)
            case .documentFrontImageOrigin:
                try container.encode("document_front_image_origin", forKey: .name)
            case .documentBackImageOrigin:
                try container.encode("document_back_image_origin", forKey: .name)
            case .cameraFacing:
                try container.encode("camera_facing", forKey: .name)
            case .documentFrontRetryCount:
                try container.encode("document_front_retry_count", forKey: .name)
            case .documentBackRetryCount:
                try container.encode("document_back_retry_count", forKey: .name)
            case .documentFrontAutoCapture:
                try container.encode("document_front_auto_capture", forKey: .name)
            case .documentBackAutoCapture:
                try container.encode("document_back_auto_capture", forKey: .name)
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
