import Foundation
import Network
import UIKit

protocol MetadataProvider {
    func collectMetadata() -> [MetadataKey: Any]
}

public class MetadataManager {
    public static let shared = MetadataManager()

    private var providers: [MetadataProvider] = []
    private var staticMetadata: [MetadataKey: Any] = [:]

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

    func addMetadata(key: MetadataKey, value: Any) {
        staticMetadata[key] = value
    }

    func removeMetadata(key: MetadataKey) {
        staticMetadata.removeValue(forKey: key)
    }

    public func getDefaultMetadata() -> [Metadatum] {
        []
    }

    func collectAllMetadata() -> [Metadatum] {
        []
    }
}
