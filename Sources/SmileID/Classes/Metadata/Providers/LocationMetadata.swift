import CoreLocation
import Foundation

class LocationMetadata: NSObject, MetadataProtocol {
    private struct GeolocationData {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        let source: String

        var asCodableObject: [String: CodableValue] {
            return [
                "latitude": .double(latitude),
                "longitude": .double(longitude),
                "accuracy": .double(accuracy),
                "source": .string(source)
            ]
        }
    }

    private var hasLocationPermission: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    func collectMetadata() -> [Metadatum] {
        var metadata: [Metadatum] = []

        // Only collect location data if permission was granted by the host app
        if hasLocationPermission {
            let locationManager = CLLocationManager()

            // Use the last known location if available
            if let location = locationManager.location {
                let geolocationData = GeolocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    accuracy: location.horizontalAccuracy,
                    source: getLocationSource(from: location.horizontalAccuracy)
                )

                metadata.append(
                    Metadatum(
                        key: MetadataKey.geolocation,
                        value: .object(geolocationData.asCodableObject),
                        date: Date()
                    )
                )
            }
        }

        return metadata
    }

    private func getLocationSource(from horizontalAccuracy: CLLocationAccuracy) -> String {
        switch horizontalAccuracy {
        case _ where horizontalAccuracy < 0:
            return "invalid"
        case 0..<5:
            return "gps"
        case 5..<10:
            return "high_accuracy"
        case 10..<100:
            return "balanced"
        case 100..<1000:
            return "low_power"
        default:
            return "coarse"
        }
    }
}

extension CLAuthorizationStatus {
    var stringValue: String {
        switch self {
        case .notDetermined:
            return "not_determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorized_always"
        case .authorizedWhenInUse:
            return "authorized_when_in_use"
        @unknown default:
            return "unknown"
        }
    }
}
