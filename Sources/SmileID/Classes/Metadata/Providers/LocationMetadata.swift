import CoreLocation
import Foundation

class LocationMetadata: NSObject, MetadataProtocol, CLLocationManagerDelegate {
    private struct LocationEvent {
        let location: CLLocation
        let date: Date = Date()
    }

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
                "source": .string(source),
            ]
        }
    }

    private let locationManager = CLLocationManager()
    private var lastKnownLocation: CLLocation?

    private var hasLocationPermission: Bool {
        let status = CLLocationManager.authorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // Only start updating location if permission is already granted
        if hasLocationPermission {
            locationManager.startUpdatingLocation()
        }
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    func collectMetadata() -> [Metadatum] {
        var metadata: [Metadatum] = []

        // Always include permission status
        metadata.append(
            Metadatum(
                key: MetadataKey.locationPermissionStatus,
                value: .string(CLLocationManager.authorizationStatus().stringValue),
                date: Date()
            )
        )

        // Only collect location data if permission was granted by the host app
        if hasLocationPermission,
            let location = lastKnownLocation
        {
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

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastKnownLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently fail - location is optional metadata
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Start/stop location updates based on current authorization
        if hasLocationPermission {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
            lastKnownLocation = nil
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
