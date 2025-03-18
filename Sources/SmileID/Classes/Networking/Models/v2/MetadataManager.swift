import Foundation
import Network
import UIKit

protocol MetadataProvider {
    func collectMetadata() -> [Metadatum]
}

class MetadataManager {
    static let shared = MetadataManager()

    private var providers: [MetadataProvider] = []
    private var staticMetadata: [Metadatum] = []

    private init() {
        setDefaultMetadata()
        registerDefaultProviders()
    }

    private func setDefaultMetadata() {
        // Set default metadata
        setStaticMetadata(item: Metadatum(name: "sdk", value: "iOS"))
        setStaticMetadata(item: Metadatum(
            name: "sdk_version", value: SmileID.version))
        setStaticMetadata(item: Metadatum(
            name: "active_liveness_version", value: "1.0.0"))
        setStaticMetadata(item: Metadatum(
            name: "client_ip", value: getIPAddress(useIPv4: true)))
        setStaticMetadata(item: Metadatum(
            name: "fingerprint", value: SmileID.deviceId))
        setStaticMetadata(item: Metadatum(
            name: "device_model", value: UIDevice.current.modelName))
        setStaticMetadata(item: Metadatum(
            name: "device_os", value: UIDevice.current.systemVersion))
    }

    private func registerDefaultProviders() {
        register(provider: NetworkMetadataProvider())
    }

    func register(provider: MetadataProvider) {
        providers.append(provider)
    }

    func setStaticMetadata(item: Metadatum) {
        staticMetadata.append(item)
    }

    func collectAllMetadata() -> [Metadatum] {
        return staticMetadata + providers.flatMap { $0.collectMetadata() }
    }
}
