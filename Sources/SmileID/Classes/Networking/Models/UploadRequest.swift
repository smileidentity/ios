import Foundation

public struct UploadRequest: Codable {
    var images: [UploadImageInfo]
    var idInfo: IdInfo?

    enum CodingKeys: String, CodingKey {
        case images
        case idInfo = "id_info"
    }
}

public struct IdInfo: Codable {
    var country: String
    var idType: String
    var idNumber: String?
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var dob: String?
    var bankCode: String?
    var entered: Bool?

    enum  CodingKeys: String, CodingKey {
        case country
        case idType = "id_type"
        case idNumber = "id_number"
        case firstName = "first_name"
        case middleName = "middle_name"
        case lastName = "last_name"
        case dob
        case bankCode = "bank_code"
        case entered
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
