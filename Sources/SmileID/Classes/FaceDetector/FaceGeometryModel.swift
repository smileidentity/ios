import Foundation

struct FaceGeometryData: Equatable {
    let boundingBox: CGRect
    let roll: NSNumber
    let yaw: NSNumber
    let pitch: NSNumber
    let direction: FaceDirection
}

enum FaceDirection {
    case left
    case right
    case none
}

struct FaceQualityData {
    let quality: Float
}

struct SelfieQualityData {
    let failed: Float
    let passed: Float
}

extension SelfieQualityData {
    static var zero: SelfieQualityData {
        return SelfieQualityData(failed: 0, passed: 0)
    }
}
