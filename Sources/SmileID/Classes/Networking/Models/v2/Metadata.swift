import Foundation

public struct Metadata: Codable {
    public var items: [Metadatum]
    
    public init(items: [Metadatum]) {
        self.items = items
    }
    
    public static func `default`() -> Metadata {
        Metadata(items: [
            .sdk,
            .sdkVersion,
            .clientIP,
            .fingerprint,
            .deviceModel,
            .deviceOS
        ])
    }
    
    public mutating func removeAllOfType<T: Metadatum>(_ type: T.Type) {
        items.removeAll { $0 is T }
    }
}

extension Array where Element == Metadatum {
    func asNetworkRequest() -> Metadata {
        return Metadata(items: self)
    }
}

public class Metadatum: Codable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, value
    }
    
    public static let sdk = Metadatum(name: "sdk", value: "iOS")
    public static let sdkVersion = Metadatum(name: "sdk_version", value: SmileID.version)
    public static let clientIP = Metadatum(name: "client_ip", value: getIPAddress(useIPv4: true))
    public static let fingerprint = Metadatum(name: "fingerprint", value: "demo2")
    public static let deviceModel = Metadatum(name: "device_model", value: UIDevice.current.model)
    public static let deviceOS = Metadatum(name: "device_os", value: UIDevice.current.systemVersion)
    
    public class SelfieImageOrigin: Metadatum {
        public init(cameraFacing: CameraFacingValue) {
            super.init(name: "selfie_image_origin", value: cameraFacing.rawValue)
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class SelfieCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(name: "selfie_capture_duration_ms", value: String(Int(duration * 1000)))
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentFrontImageOrigin: Metadatum {
        public init(origin: DocumentImageOriginValue) {
            super.init(name: "document_front_image_origin", value: origin.rawValue)
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentBackImageOrigin: Metadatum {
        public init(origin: DocumentImageOriginValue) {
            super.init(name: "document_back_image_origin", value: origin.rawValue)
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentFrontCaptureRetries: Metadatum {
        public init(retries: Int) {
            super.init(name: "document_front_capture_retries", value: String(retries))
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentBackCaptureRetries: Metadatum {
        public init(retries: Int) {
            super.init(name: "document_back_capture_retries", value: String(retries))
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentFrontCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(name: "document_front_capture_duration_ms", value: String(Int(duration * 1000)))
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    public class DocumentBackCaptureDuration: Metadatum {
        public init(duration: TimeInterval) {
            super.init(name: "document_back_capture_duration_ms", value: String(Int(duration * 1000)))
        }
        
        required public init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
}
public enum DocumentImageOriginValue: String {
    case gallery = "gallery"
    case cameraAutoCapture = "camera_auto_capture"
    case cameraManualCapture = "camera_manual_capture"
    
    public var value: String {
        return self.rawValue
    }
}

public enum CameraFacingValue: String, Codable {
    case frontCamera = "front_camera"
    case backCamera = "back_camera"
}

func getIPAddress(useIPv4: Bool) -> String {
    var address: String = ""
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
            if name == "en0" || name == "en1" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
                
                if (useIPv4 && addrFamily == UInt8(AF_INET)) ||
                    (!useIPv4 && addrFamily == UInt8(AF_INET6)) {
                    if !useIPv4 {
                        if let percentIndex = address.firstIndex(of: "%") {
                            address = String(address[..<percentIndex]).uppercased()
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
    @Published var metadata: Metadata = Metadata.default()
    
    func addMetadata(_ newMetadata: Metadatum) {
        metadata.items.append(newMetadata)
        objectWillChange.send()
    }
}
