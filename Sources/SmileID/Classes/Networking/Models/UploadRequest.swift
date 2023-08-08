import Foundation

public struct UploadRequest: Codable {
    var images: [UploadImageInfo]

    enum CodingKeys: String, CodingKey {
        case images
    }
}

public struct UploadImageInfo: Codable {
    var imageTypeId: ImageType
    var fileName: String

    enum CodingKeys: String, CodingKey {
        case imageTypeId = "image_type_id"
        case fileName = "file_name"
    }
}

public enum ImageType: String, Codable {
    case selfieJpgFile = "0"
    case idCardJpgFile = "1"
    case selfieJpgBase64 = "2"
    case idCardJpgBase64 = "3"
    case livenessJpgFile = "4"
    case idCardRearJpgFile = "5"
    case livenessJpgBase64 = "6"
    case idCardRearJpgBase64 = "7"
}
