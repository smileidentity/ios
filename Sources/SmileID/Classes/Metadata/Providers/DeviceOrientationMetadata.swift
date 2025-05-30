import CoreMotion
import Foundation
import UIKit

class DeviceOrientationMetadata: MetadataProtocol {
    var provides: [MetadataKey] = [.deviceOrientation, .deviceMovementDetected]

    private let motionManager = CMMotionManager()
    var isRecording = false

    private struct OrientationEvent {
        let value: String
        let date: Date = Date()
    }

    private enum OrientationType: String {
        case portrait = "portrait"
        case landscape = "landscape"
        case flat = "flat"
        case unknown = "unknown"
    }

    private var currentOrientation: OrientationType = OrientationType.unknown
    private var deviceOrientations: [OrientationEvent] = []
    private var deviceMovements: [Double] = []

    func onStart() {
        guard motionManager.isAccelerometerAvailable else {
            return
        }

        // If we're already recording, then we don't start again
        if isRecording {
            return
        }
        isRecording = true

        // Clear previous history to start fresh recording session
        deviceOrientations.removeAll()
        deviceMovements.removeAll()

        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            self.currentOrientation = self.detectOrientationChange(from: data)
            self.detectMovementChange(from: data)
        }
    }

    func onStop() {
        isRecording = false
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }

    private func detectOrientationChange(from data: CMAccelerometerData) -> OrientationType {
        let accelerationX = data.acceleration.x
        let accelerationY = data.acceleration.y
        let accelerationZ = data.acceleration.z

        if abs(accelerationZ) > 0.85 {
            return OrientationType.flat
        } else if abs(accelerationY) > abs(accelerationX) {
            return OrientationType.portrait
        } else {
            return OrientationType.landscape
        }
    }

    private func detectMovementChange(from data: CMAccelerometerData) {
        let accelerationX = data.acceleration.x
        let accelerationY = data.acceleration.y
        let accelerationZ = data.acceleration.z

        // Calculate acceleration magnitude
        let magnitude = sqrt(
            accelerationX * accelerationX +
            accelerationY * accelerationY +
            accelerationZ * accelerationZ
        )

        let gravity = 0.981
        let movementChange = abs(magnitude - gravity)
        deviceMovements.append(movementChange)
    }

    func collectMetadata() -> [Metadatum] {
        let orientations = deviceOrientations.map {
            Metadatum(
                key: .deviceOrientation,
                value: .string($0.value),
                date: $0.date
            )
        }

        /*
         The movement change is the difference between the minimum movement change and the
         maximum movement change.
        */
        let movementChange: Double = {
            if let minMovementChange = deviceMovements.min(),
               let maxMovementChange = deviceMovements.max() {
                return maxMovementChange - minMovementChange
            } else {
                return -1.0
            }
        }()
        let movement = Metadatum(
            key: .deviceMovementDetected,
            value: .double(movementChange)
        )
        return orientations + [movement]
    }

    func addMetadata(forKey: MetadataKey) {
        switch forKey {
        case .deviceOrientation:
            deviceOrientations.append(
                OrientationEvent(value: currentOrientation.rawValue)
            )
        default:
            // ignore the other cases
            break
        }
    }

    func removeMetadata(forKey: MetadataKey) {
        switch forKey {
        case .deviceOrientation:
            deviceOrientations.removeAll()
        case .deviceMovementDetected:
            deviceMovements.removeAll()
        default:
            // ignore the other cases
            break
        }
    }
}
