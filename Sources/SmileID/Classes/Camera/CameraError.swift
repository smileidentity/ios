import Foundation

enum CameraError: Error {
    case cameraUnavailable
    case restrictedAuthorization
    case deniedAuthorization
    case unknownAuthorization
    case cannotAddInput
    case cannotAddOutput
    case createCaptureInput(Error)
    case cannotCaptureImage(Error?)
}
