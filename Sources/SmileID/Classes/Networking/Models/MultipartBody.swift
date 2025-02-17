import Foundation

public struct MultipartBody: Codable {
    let data: Data
    let filename: String
    let mimeType: String

    public init?(
        withImage image: Data,
        forName name: String
    ) {
        self.data = image
        self.filename = name
        self.mimeType = "image/jpeg"
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case filename = "name"
        case mimeType = "type"
    }
    
    /*public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data.base64EncodedString(), forKey: .data)
        try container.encode(filename, forKey: .filename)
        try container.encode(mimeType, forKey: .mimeType)
    }*/
}
