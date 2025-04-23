import Foundation
import UIKit
import CoreMotion

class DeviceOrientationMetadataProvider: MetadataProvider {
    static let shared = DeviceOrientationMetadataProvider()

    private let motionManager = CMMotionManager()

    private(set) var currentOrientation: String = "unknown"
    private var deviceOrientations: [String] = []

    private init() {}

    func startRecordingDeviceOrientations() {
        guard motionManager.isAccelerometerAvailable else {
            return
        }

        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.currentOrientation = self.determineOrientation(from: data)
        }
    }

    private func stopRecordingDeviceOrientations() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }

    private func determineOrientation(from data: CMAccelerometerData) -> String {
        let accelerationX = data.acceleration.x
        let accelerationY = data.acceleration.y
        let accelerationZ = data.acceleration.z

        if abs(accelerationZ) > 0.85 {
            return "Flat"
        } else if abs(accelerationY) > abs(accelerationX) {
            return "Portrait"
        } else {
            return "Landscape"
        }
    }

    func addDeviceOrientation() {
        deviceOrientations.append(currentOrientation)
    }

    func clearDeviceOrientations() {
        deviceOrientations.removeAll()
    }

    // MARK: - MetadataProvider Protocol

    func collectMetadata() -> [MetadataKey: String] {
        stopRecordingDeviceOrientations()

        // Ensure we clean up the device orientations always at the end, regardless of early returns
        defer { deviceOrientations.removeAll() }

        guard let jsonString = jsonString(from: deviceOrientations), !jsonString.isEmpty else {
            return [:]
        }

        return [.deviceOrientation: jsonString]
    }
}
