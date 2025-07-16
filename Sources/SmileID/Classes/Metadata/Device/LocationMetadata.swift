import CoreLocation

struct LocationInfo {
  var latitude: Double
  var longitude: Double
  var accuracy: LocationAccuracy
  var source: LocationSource

  static let unknown = LocationInfo(
    latitude: 0.0,
    longitude: 0.0,
    accuracy: LocationAccuracy.unknown,
    source: LocationSource.unknown)

  func toCodableObject() -> [String: CodableValue] {
    [
      "latitude": .double(latitude),
      "longitude": .double(longitude),
      "accuracy": .string(accuracy.rawValue),
      "source": .string(source.rawValue)
    ]
  }
}

enum LocationAccuracy: String {
  case approximate
  case precise
  case unknown
}

enum LocationSource: String {
  case gps
  case network
  case fused
  case unknown
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
    source: source)
  return locationInfo
}
