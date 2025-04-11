import Foundation
import Network
import UIKit

protocol MetadataProvider {
    func collectMetadata() -> [MetadataKey: String]
}

public class MetadataManager {
    public static let shared = MetadataManager()

    private var providers: [MetadataProvider] = []
    private var staticMetadata: [MetadataKey: String] = [:]

    private init() {
        setDefaultMetadata()
        registerDefaultProviders()
    }

    private func setDefaultMetadata() {
        addMetadata(key: .sdk, value: "iOS")
        addMetadata(key: .sdkVersion, value: SmileID.version)
        addMetadata(key: .activeLivenessVersion, value: "1.0.0")
        addMetadata(
            key: .clientIP, value: getIPAddress(useIPv4: true))
        addMetadata(
            key: .fingerprint, value: SmileID.deviceId)
        addMetadata(
            key: .deviceModel, value: UIDevice.current.modelName)
        addMetadata(
            key: .deviceOS, value: UIDevice.current.systemVersion)
    }

    private func registerDefaultProviders() {}

    func register(provider: MetadataProvider) {
        providers.append(provider)
    }

    func addMetadata(key: MetadataKey, value: String) {
        staticMetadata[key] = value
    }

    func removeMetadata(key: MetadataKey) {
        staticMetadata.removeValue(forKey: key)
    }

    public func getDefaultMetadata() -> [Metadatum] {
        return staticMetadata.map {
            Metadatum(name: $0.key.rawValue, value: $0.value)
        }
    }

    func collectAllMetadata() -> [Metadatum] {
        var allMetadata = staticMetadata

        for provider in providers {
            let providerMetadata = provider.collectMetadata()
            for (key, value) in providerMetadata {
                allMetadata[key] = value
            }
        }

        return allMetadata.map { key, value in
            Metadatum(name: key.rawValue, value: value)
        }
    }
}
