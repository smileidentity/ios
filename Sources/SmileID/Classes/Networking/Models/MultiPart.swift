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
    var userId: String? = nil
    var callbackUrl: String? = nil
    var sandboxResult: Int? = nil
    var allowNewEnroll: Bool? = nil
    var partnerParams: [String: String]? = nil
}
