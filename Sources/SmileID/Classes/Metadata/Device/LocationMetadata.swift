import CoreLocation

struct LocationInfo {
    public var latitude: Double
    public var longitude: Double
    public var accuracy: LocationAccuracy
    public var source: LocationSource

    static let unknown = LocationInfo(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: LocationAccuracy.unknown,
        source: LocationSource.unknown
    )

    func toCodableObject() -> [String: CodableValue] {
        return [
            "latitude": .double(self.latitude),
            "longitude": .double(self.longitude),
            "accuracy": .string(self.accuracy.rawValue),
            "source": .string(self.source.rawValue)
        ]
    }
}

enum LocationAccuracy: String {
    case approximate = "approximate"
    case precise = "precise"
    case unknown = "unknown"
}

enum LocationSource: String {
    case gps = "gps"
    case network = "network"
    case fused = "fused"
    case unknown = "unknown"
}

func currentLocation() -> LocationInfo {
    let status = CLLocationManager.authorizationStatus()
    guard status == .authorizedWhenInUse || status == .authorizedAlways else {
        return LocationInfo.unknown
    }

    let locationManager = CLLocationManager()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest

    guard let location = locationManager.location else {
        return LocationInfo.unknown
    }

    // We infer the location source from the location accuracy.
    let (accuracy, source): (LocationAccuracy, LocationSource) = {
        switch location.horizontalAccuracy {
        case 0..<20: return (.precise, .gps)
        case 20..<100: return (.approximate, .network)
        default: return (.unknown, .unknown)
        }
    }()

    let locationInfo = LocationInfo(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        accuracy: accuracy,
        source: source
    )
    return locationInfo
}
