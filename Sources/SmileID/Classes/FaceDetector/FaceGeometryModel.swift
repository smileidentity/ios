import Foundation

struct FaceGeometryModel: Equatable {
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

struct FaceQualityModel {
    let quality: Float
}

struct SelfieQualityModel {
    let failed: Float
    let passed: Float
}

extension SelfieQualityModel {
    static var zero: SelfieQualityModel {
        return SelfieQualityModel(failed: 0, passed: 1)
    }
}
