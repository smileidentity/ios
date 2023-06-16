import Foundation

struct FaceGeometryModel: Equatable {
    let boundingBox: CGRect
    let roll: NSNumber
    let yaw: NSNumber
}

struct FaceQualityModel: Equatable {
    let quality: Float
}
