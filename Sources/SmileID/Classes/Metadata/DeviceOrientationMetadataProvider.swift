import CoreMotion
import Foundation
import UIKit

class DeviceOrientationMetadataProvider: MetadataProvider {
    static let shared = DeviceOrientationMetadataProvider()

    private let motionManager = CMMotionManager()

    private struct OrientationEvent {
        let value: String
        let date: Date = Date()
    }
    private(set) var currentOrientation: String = "unknown"
    private var deviceOrientations: [OrientationEvent] = []
    var isRecordingDeviceOrientations = false

    private init() {}

    func startRecordingDeviceOrientations() {
        guard motionManager.isAccelerometerAvailable else {
            return
        }

        if isRecordingDeviceOrientations {
            // Early return if we are already recording the device orientations
            return
        }
        isRecordingDeviceOrientations = true

        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.currentOrientation = self.determineOrientation(from: data)
        }
    }

    private func stopRecordingDeviceOrientations() {
        isRecordingDeviceOrientations = false
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
        deviceOrientations.append(
            OrientationEvent(value: currentOrientation)
        )
    }

    func clearDeviceOrientations() {
        deviceOrientations.removeAll()
    }

    // MARK: - MetadataProvider Protocol

    func collectMetadata() -> [Metadatum] {
        stopRecordingDeviceOrientations()

        // Ensure we clean up the device orientations always at the end, regardless of early returns
        defer { deviceOrientations.removeAll() }

        return deviceOrientations.map {
            Metadatum(
                key: .deviceOrientation,
                value: .string($0.value),
                date: $0.date
            )
        }
    }
}
