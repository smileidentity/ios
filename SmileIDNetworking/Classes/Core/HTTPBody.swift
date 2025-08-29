import Foundation

enum HTTPBody {
  case json(Encodable)
  case formURLEncoded([String: String])
  case multipart(MultipartFormData)
}
