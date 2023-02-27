import Foundation

public struct UploadRequest: Codable {
    var images: [UploadImageInfo]
    var packageInfo = UploadPackageInfo()

    enum CodingKeys: String, CodingKey {
        case images
        case packageInfo = "package_information"
    }
}

public struct UploadImageInfo: Codable {
    var imageTypeId: ImageType
    var image: String

    enum CodingKeys: String, CodingKey {
        case imageTypeId = "image_type_id"
        case image
    }
}

public struct UploadPackageInfo: Codable {
    var apiVersion = ApiVersion()
    var versionNames = VersionNames()

    enum CodingKeys: String, CodingKey {
        case apiVersion
        case versionNames = "version_names"
    }
}

public struct ApiVersion: Codable {
    var buildNumber = 2
    var majorVersion = 2
    var minorVersion = 1
}

public struct VersionNames: Codable {
    // TO-DO: Dynamically fetch SDK version from Package.swift
    var version = "3.0.0"
    var sdkType = "iOS"

    enum CodingKeys: String, CodingKey {
        case version = "sid_sdk_version"
        case sdkType = "sid_sdk_type"
    }
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
