import Foundation
import UIKit

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

    var orientationString: String {
        switch UIDevice.current.orientation {
        case .portrait, .portraitUpsideDown:
            return "Portrait"
        case .landscapeLeft, .landscapeRight:
            return "Landscape"
        case .faceUp:
            return "FaceUp"
        case .faceDown:
            return "FaceDown"
        case .unknown:
            // Default to UI orientation if device orientation is unknown
            let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
            switch interfaceOrientation {
            case .portrait, .portraitUpsideDown:
                return "Portrait"
            case .landscapeLeft, .landscapeRight:
                return "Landscape"
            case .unknown, .none:
                return "Unknown"
            @unknown default:
                return "Unknown"
            }
        @unknown default:
            return "Unknown"
        }
    }

    /// Checks if the device has a proximity sensor available
    var hasProximitySensor: Bool {
        // When proximity monitoring is enabled, device will receive proximity state change notifications
        UIDevice.current.isProximityMonitoringEnabled = true
        let hasProximitySensor = UIDevice.current.isProximityMonitoringEnabled

        // Reset to false to avoid unnecessary battery drain
        UIDevice.current.isProximityMonitoringEnabled = false

        return hasProximitySensor
    }

    /// String representation of proximity sensor availability (true/false)
    var proximitySensorString: String {
        return String(hasProximitySensor)
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
