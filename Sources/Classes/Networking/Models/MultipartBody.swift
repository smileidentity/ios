import Foundation

public struct MultipartBody: Codable {
  let data: Data
  let filename: String
  let mimeType: String

  public init?(
    withImage image: Data,
    forName name: String
  ) {
    data = image
    filename = name
    mimeType = "image/jpeg"
  }

  enum CodingKeys: String, CodingKey {
    case data
    case filename = "name"
    case mimeType = "type"
  }
}
