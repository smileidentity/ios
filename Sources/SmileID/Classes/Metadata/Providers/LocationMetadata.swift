import CoreLocation

class LocationMetadata: NSObject, MetadataProtocol {
    static let shared = LocationMetadata()

    private let locationManager = CLLocationManager()
    private var locationInfos: [LocationEvent] = []

    private struct LocationEvent {
        let value: LocationInfo
        let date: Date = Date()
    }

    private struct LocationInfo {
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
    }

    private enum LocationAccuracy: String {
        case approximate = "approximate"
        case precise = "precise"
        case unknown = "unknown"
    }

    private enum LocationSource: String {
        case gps = "gps"
        case network = "network"
        case fused = "fused"
        case unknown = "unknown"
    }

    private override init() {
        super.init()
        //locationManager.delegate = self CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        onStart()
    }

    deinit {
        onStop()
    }

    private func onStart() {
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            locationInfos.append(
                LocationEvent(
                    value: LocationInfo.unknown
                )
            )
            return
        }

        locationInfos = []
        updateLocation()
    }

    private func onStop() {
        locationManager.stopUpdatingLocation()
        //locationManager.delegate = nil
    }

    func updateLocation() {
        guard let location = self.locationManager.location else {
            locationInfos.append(
                LocationEvent(
                    value: LocationInfo.unknown
                )
            )
            return
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
        locationInfos.append(
            LocationEvent(
                value: locationInfo
            )
        )
    }

    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error")
        print(error)
    }*/

    func collectMetadata() -> [Metadatum] {
        let metadata = locationInfos.map {
            Metadatum(
                key: .geolocation,
                value: .object(
                    [
                        "latitude": .double($0.value.latitude),
                        "longitude": .double($0.value.longitude),
                        "accuracy": .string($0.value.accuracy.rawValue),
                        "source": .string($0.value.source.rawValue)
                    ]
                ),
                date: $0.date
            )
        }
        return metadata
    }
}
