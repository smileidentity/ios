import Foundation

public struct UploadRequest: Codable {
    var images: [UploadImageInfo]
    var packageInfo: UploadPackageInfo
}

public struct UploadImageInfo: Codable {
    var imageTypeId: ImageType
    var image: String
}

public struct UploadPackageInfo: Codable {
    var imageTypeId: ImageType
}

public enum ImageType: String, Codable {
    case selfiePngOrJpgFile = "0"
    case idCardPngOrJpgFile = "1"
    case selfiePngOrJpgBase64 = "2"
    case idCardPngOrJpgBase64 = "3"
    case livenessPngOrJpgFile = "4"
    case idCardRearPngOrJpgFile = "5"
    case livenessPngOrJpgBase64 = "6"
    case idCardRearPngOrJpgBase64 = "7"
}
