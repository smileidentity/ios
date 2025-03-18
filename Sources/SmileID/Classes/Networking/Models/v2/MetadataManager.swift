import Foundation
import Network
import UIKit

protocol MetadataProvider {
    func collectMetadata() -> [MetadataKey: AnyCodable]
}

public class MetadataManager {
    public static let shared = MetadataManager()

    private var providers: [MetadataProvider] = []
    private var staticMetadata: [MetadataKey: AnyCodable] = [:]

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

    private func registerDefaultProviders() {
        register(provider: NetworkMetadataProvider())
    }

    func register(provider: MetadataProvider) {
        providers.append(provider)
    }

    func addMetadata<T: Codable>(key: MetadataKey, value: T) {
        staticMetadata[key] = AnyCodable(value)
    }

    func removeMetadata(key: MetadataKey) {
        staticMetadata.removeValue(forKey: key)
    }

    public func getDefaultMetadata() -> [Metadatum] {
        return staticMetadata.map {
            Metadatum(key: $0.key, value: $0.value)
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
            Metadatum(key: key, value: value)
        }
    }
}
