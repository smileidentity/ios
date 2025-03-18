import Foundation

class ActiveLivenessType: Metadatum {
    init(livenessType: LivenessType) {
        super.init(
            name: "active_liveness_type", value: livenessType.rawValue)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class SelfieImageOrigin: Metadatum {
    init(cameraFacing: CameraFacingValue) {
        super.init(
            name: "selfie_image_origin", value: cameraFacing.rawValue)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class SelfieCaptureDuration: Metadatum {
    init(duration: TimeInterval) {
        super.init(
            name: "selfie_capture_duration_ms",
            value: String(Int(duration * 1000)))
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentFrontImageOrigin: Metadatum {
    init(origin: DocumentImageOriginValue) {
        super.init(
            name: "document_front_image_origin", value: origin.rawValue)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentBackImageOrigin: Metadatum {
    init(origin: DocumentImageOriginValue) {
        super.init(
            name: "document_back_image_origin", value: origin.rawValue)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentFrontCaptureRetries: Metadatum {
    init(retries: Int) {
        super.init(
            name: "document_front_capture_retries", value: String(retries))
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentBackCaptureRetries: Metadatum {
    init(retries: Int) {
        super.init(
            name: "document_back_capture_retries", value: String(retries))
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentFrontCaptureDuration: Metadatum {
    init(duration: TimeInterval) {
        super.init(
            name: "document_front_capture_duration_ms",
            value: String(Int(duration * 1000)))
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DocumentBackCaptureDuration: Metadatum {
    init(duration: TimeInterval) {
        super.init(
            name: "document_back_capture_duration_ms",
            value: String(Int(duration * 1000)))
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class NetworkConnection: Metadatum {
    init() {
        super.init(
            name: "network_connection",
            value: NetworkConnectionProvider.shared.getCurrentConnectionType())
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

enum LivenessType: String, Codable {
    case headPose = "head_pose"
    case smile = "smile"
}

enum DocumentImageOriginValue: String {
    case gallery
    case cameraAutoCapture = "camera_auto_capture"
    case cameraManualCapture = "camera_manual_capture"
    var value: String {
        return rawValue
    }
}

enum CameraFacingValue: String, Codable {
    case frontCamera = "front_camera"
    case backCamera = "back_camera"
}
