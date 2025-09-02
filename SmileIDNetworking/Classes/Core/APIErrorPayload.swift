import Foundation

struct APIErrorPayload: Decodable {
  let code: String?
  let message: String?
}
