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
