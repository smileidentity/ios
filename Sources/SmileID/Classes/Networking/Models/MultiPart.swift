import Foundation

struct MultiPartMedia: Encodable {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String

    init?(withImage image: Data, forKey key: String, forName name: String) {
        self.key = key
        mimeType = "image/jpeg"
        filename = name
        data = image
    }
}

public struct MultiPartRequest: Encodable {
    let multiPartMedia: [MultiPartMedia]
    var userId: String?
    var callbackUrl: String?
    var sandboxResult: Int?
    var allowNewEnroll: Bool?
    var partnerParams: [String: String]?
}
