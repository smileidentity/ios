import AVFoundation
import Foundation
import Network
import UIKit

class Metadata {
    static let shared = Metadata()

    private struct StaticEntry {
        let value: CodableValue
        let date: Date = Date()
    }
    private var providers: [MetadataProtocol] = []
    private var staticMetadata: [MetadataKey: StaticEntry] = [:]

    private init() {}

    func initialize() {
        reset()
        setDefaultMetadata()
        registerDefaultProviders()
    }

    private func reset() {
        staticMetadata.removeAll()
        providers.removeAll()
    }

    private func setDefaultMetadata() {
        addMetadata(key: .activeLivenessVersion, value: "1.0.0")
        addMetadata(key: .clientIP, value: getIPAddress(useIPv4: true))
        addMetadata(key: .deviceModel, value: UIDevice.current.modelName)
        addMetadata(key: .deviceOS, value: UIDevice.current.systemVersion)
        addMetadata(key: .fingerprint, value: SmileID.deviceId)
        addMetadata(key: .hostApplication, value: Bundle.main.hostApplicationInfo)
        addMetadata(key: .locale, value: Locale.current.identifier)
        addMetadata(
            key: .localTimeOfEnrolment, value: Date().toISO8601WithMilliseconds(timezone: .current)
        )
        addMetadata(key: .geolocation, value: currentLocation().toCodableObject())
        addMetadata(key: .memoryInfo, value: ProcessInfo.processInfo.availableMemoryInMB)
        addMetadata(key: .numberOfCameras, value: AVCaptureDevice.numberOfCameras)
        addMetadata(key: .proximitySensor, value: UIDevice.current.hasProximitySensor)
        addMetadata(key: .proxyDetected, value: isProxyDetected())
        addMetadata(key: .screenResolution, value: UIScreen.main.formattedResolution)
        addMetadata(key: .securityPolicyVersion, value: "0.3.0")
        addMetadata(key: .sdk, value: "iOS")
        addMetadata(key: .fingerprint, value: SmileID.deviceId)
        addMetadata(key: .sdkLaunchCount, value: SmileID.sdkLaunchCount)
        addMetadata(key: .sdkVersion, value: SmileID.version)
        addMetadata(key: .systemArchitecture, value: ProcessInfo.processInfo.systemArchitecture)
        addMetadata(key: .timezone, value: TimeZone.current.identifier)
        addMetadata(key: .vpnDetected, value: isVPNActive())
        if let wrapperSdkName = SmileID.wrapperSdkName {
            addMetadata(key: .wrapperName, value: wrapperSdkName.rawValue)
        }
        if let wrapperSdkVersion = SmileID.wrapperSdkVersion {
            addMetadata(key: .wrapperVersion, value: wrapperSdkVersion)
        }
    }

    private func registerDefaultProviders() {
        register(provider: NetworkMetadata())
        register(provider: DeviceOrientationMetadata())
    }

    private func register(provider: MetadataProtocol) {
        providers.append(provider)
    }

    func removeMetadata(key: MetadataKey) {
        staticMetadata.removeValue(forKey: key)

        for provider in providers {
            if provider.provides.contains(key) {
                provider.removeMetadata(forKey: key)
            }
        }
    }

    func getDefaultMetadata() -> [Metadatum] {
        return staticMetadata.map { key, entry in
            Metadatum(
                key: key,
                value: entry.value,
                date: entry.date
            )
        }
    }

    func onStart() {
        for provider in providers {
            provider.onStart()
        }
    }

    func onStop() {
        for provider in providers {
            provider.onStop()
        }
    }

    func collectAllMetadata() -> [Metadatum] {
        var allMetadata = getDefaultMetadata()
        for provider in providers {
            allMetadata.append(contentsOf: provider.collectMetadata())
        }
        return allMetadata
    }
}

// Strongly-typed overloads for adding metadatata
extension Metadata {
    private func store(_ key: MetadataKey, _ value: CodableValue) {
        staticMetadata[key] = StaticEntry(value: value)
    }

    func addMetadata(key: MetadataKey, value: String) {
        store(key, .string(value))
    }

    func addMetadata(key: MetadataKey, value: Int) {
        store(key, .int(value))
    }

    func addMetadata(key: MetadataKey, value: Double) {
        store(key, .double(value))
    }

    func addMetadata(key: MetadataKey, value: Bool) {
        store(key, .bool(value))
    }

    func addMetadata(key: MetadataKey, value: [CodableValue]) {
        store(key, .array(value))
    }

    func addMetadata(key: MetadataKey, value: [String: CodableValue]) {
        store(key, .object(value))
    }

    func addMetadata(key: MetadataKey) {
        for provider in providers {
            if provider.provides.contains(key) {
                provider.addMetadata(forKey: key)
            }
        }
    }
}
