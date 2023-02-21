import Foundation

struct UploadRequest {
    var images: [UploadImageInfo]
}

struct UploadImageInfo {
    var imageTypeId: ImageType
    var image: String
}

enum ImageType: String {
    case selfiePngOrJpgFile = "0"
    case idCardPngOrJpgFile = "1"
    case selfiePngOrJpgBase64 = "2"
    case idCardPngOrJpgBase64 = "3"
    case livenessPngOrJpgFile = "4"
    case idCardRearPngOrJpgFile = "5"
    case livenessPngOrJpgBase64 = "6"
    case idCardRearPngOrJpgBase64 = "7"
}
