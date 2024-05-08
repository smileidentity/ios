import Foundation

struct MultiPartMedia: Encodable {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String

    init?(withImage image: Data, forKey key: String, forName name: String) {
        self.key = key
        self.mimeType = "image/jpeg"
        self.filename = name
        self.data = image
    }
}

typealias MultiPartParameters = [String: String]

public struct MultiPartRequest: Encodable {
    let multiPartMedia: [MultiPartMedia]
    let multiPartParams: MultiPartParameters?
}
