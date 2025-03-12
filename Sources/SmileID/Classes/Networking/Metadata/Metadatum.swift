import Foundation

public class Metadatum: Codable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
    }

    private enum CodingKeys: String, CodingKey {
        case name, value
    }

    public static let sdk = Metadatum(name: "sdk", value: "iOS")
    public static let sdkVersion = Metadatum(
        name: "sdk_version", value: SmileID.version)
    public static let activeLivenessVersion = Metadatum(
        name: "active_liveness_version", value: "1.0.0")
    public static let clientIP = Metadatum(
        name: "client_ip", value: getIPAddress(useIPv4: true))
    public static let fingerprint = Metadatum(
        name: "fingerprint", value: SmileID.deviceId)
    public static let deviceModel = Metadatum(
        name: "device_model", value: UIDevice.current.modelName)
    public static let deviceOS = Metadatum(
        name: "device_os", value: UIDevice.current.systemVersion)
    public static let networkConnection = Metadatum(
        name: "network_connection", value: NetworkConnectionProvider.shared.getCurrentConnectionType())

    public class ActiveLivenessType: Metadatum {
        public init(livenessType: LivenessType) {
            super.init(
                name: "active_liveness_type", value: livenessType.rawValue)
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class SelfieImageOrigin: Metadatum {
        public init(cameraFacing: CameraFacingValue) {
            super.init(
                name: "selfie_image_origin", value: cameraFacing.rawValue)
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class SelfieCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(
                name: "selfie_capture_duration_ms",
                value: String(Int(duration * 1000)))
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentFrontImageOrigin: Metadatum {
        public init(origin: DocumentImageOriginValue) {
            super.init(
                name: "document_front_image_origin", value: origin.rawValue)
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentBackImageOrigin: Metadatum {
        public init(origin: DocumentImageOriginValue) {
            super.init(
                name: "document_back_image_origin", value: origin.rawValue)
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentFrontCaptureRetries: Metadatum {
        public init(retries: Int) {
            super.init(
                name: "document_front_capture_retries", value: String(retries))
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentBackCaptureRetries: Metadatum {
        public init(retries: Int) {
            super.init(
                name: "document_back_capture_retries", value: String(retries))
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentFrontCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(
                name: "document_front_capture_duration_ms",
                value: String(Int(duration * 1000)))
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }

    public class DocumentBackCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(
                name: "document_back_capture_duration_ms",
                value: String(Int(duration * 1000)))
        }

        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class NetworkConnection: Metadatum {
        public init() {
            super.init(
                name: "network_connection",
                value: NetworkConnectionProvider.shared.getCurrentConnectionType())
        }
        
        public required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
}

public enum LivenessType: String, Codable {
    case headPose = "head_pose"
    case smile = "smile"
}

public enum DocumentImageOriginValue: String {
    case gallery
    case cameraAutoCapture = "camera_auto_capture"
    case cameraManualCapture = "camera_manual_capture"
    public var value: String {
        return rawValue
    }
}

public enum CameraFacingValue: String, Codable {
    case frontCamera = "front_camera"
    case backCamera = "back_camera"
}
