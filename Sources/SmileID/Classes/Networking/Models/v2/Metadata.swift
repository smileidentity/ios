import Foundation
import UIKit

public struct Metadata: Codable {
    public var items: [Metadatum]
    public init(items: [Metadatum]) {
        self.items = items
    }

    public static func `default`() -> Metadata {
        Metadata(items: [
            .sdk,
            .sdkVersion,
            .activeLivenessVersion,
            .clientIP,
            .fingerprint,
            .deviceModel,
            .deviceOS
        ])
    }

    public mutating func removeAllOfType<T: Metadatum>(_: T.Type) {
        items.removeAll { $0 is T }
    }
}

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

func getIPAddress(useIPv4: Bool) -> String {
    var address = ""
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&ifaddr) == 0 else {
        return ""
    }

    var ptr = ifaddr
    while ptr != nil {
        defer { ptr = ptr?.pointee.ifa_next }

        guard let interface = ptr?.pointee else {
            return ""
        }

        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            let name = String(cString: interface.ifa_name)
            if name == "en0" || name == "en1" || name == "pdp_ip0"
                || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname, socklen_t(hostname.count),
                    nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)

                if (useIPv4 && addrFamily == UInt8(AF_INET))
                    || (!useIPv4 && addrFamily == UInt8(AF_INET6)) {
                    if !useIPv4 {
                        if let percentIndex = address.firstIndex(of: "%") {
                            address = String(address[..<percentIndex])
                                .uppercased()
                        } else {
                            address = address.uppercased()
                        }
                    }
                    break
                }
            }
        }
    }

    freeifaddrs(ifaddr)
    return address
}

public class LocalMetadata: ObservableObject {
    @Published var metadata: Metadata = .default()
    public init() {}

    func addMetadata(_ newMetadata: Metadatum) {
        metadata.items.append(newMetadata)
        objectWillChange.send()
    }
}

extension UIDevice {
    var modelName: String {
        #if targetEnvironment(simulator)
            let identifier = ProcessInfo().environment[
                "SIMULATOR_MODEL_IDENTIFIER"]!
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else {
                    return identifier
                }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
        return DeviceModel.all.first { $0.identifier == identifier }?.model
            ?? identifier
    }

    struct DeviceModel: Decodable {
        let identifier: String
        let model: String
        static var all: [DeviceModel] {
            _ = UIDevice.current.name
            guard
                let devicesUrl = SmileIDResourcesHelper.bundle.url(
                    forResource: "devicemodels", withExtension: "json"
                )
            else { return [] }
            do {
                let data = try Data(contentsOf: devicesUrl)
                let devices = try JSONDecoder().decode(
                    [DeviceModel].self, from: data)
                return devices
            } catch {
                print("Error decoding device models: \(error)")
                return []
            }
        }
    }
}
