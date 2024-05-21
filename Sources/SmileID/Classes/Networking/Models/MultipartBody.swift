import Foundation

public struct MultipartBody: Encodable {
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
