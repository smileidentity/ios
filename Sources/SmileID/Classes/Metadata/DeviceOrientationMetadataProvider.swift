import Foundation
import UIKit

class DeviceOrientationMetadataProvider: MetadataProvider {
    static let shared = DeviceOrientationMetadataProvider()

    // Store all device orientations captured during the flow
    private var deviceOrientations: [UIDeviceOrientation] = []

    private init() {}

    /// Adds a device orientation to the collection
    /// - Parameter orientation: The UIDeviceOrientation to add
    func addDeviceOrientation(_ orientation: UIDeviceOrientation) {
        deviceOrientations.append(orientation)
    }

    /// Adds multiple device orientations to the collection
    /// - Parameter orientations: Array of UIDeviceOrientation to add
    func addDeviceOrientations(_ orientations: [UIDeviceOrientation]) {
        deviceOrientations.append(contentsOf: orientations)
    }

    /// Clears all stored orientation data
    func clearDeviceOrientations() {
        deviceOrientations.removeAll()
    }

    // MARK: - MetadataProvider Protocol

    func collectMetadata() -> [MetadataKey: String] {
        // Only add orientation data if we have captured values
        guard !deviceOrientations.isEmpty else {
            return [:]
        }

        // Convert the orientations to their string categories
        let orientationCategories = deviceOrientations.map { $0.category }

        // We clear the device orientations after we collected them
        deviceOrientations.removeAll()

        // Convert the orientation data to a JSON string
        if let jsonString = jsonString(from: orientationCategories) {
            return [.deviceOrientation: jsonString]
        }

        return [:]
    }
}
