import Foundation

// Internal header hints used between builder and middlewares.
// Removed before transport.
enum InternalHeaders {
  static let needsAuth = "X-Smile-Needs-Auth"
  static let needsSignature = "X-Smile-Needs-Signature" // values: header, body
  static let needsEncryption = "X-Smile-Needs-Encryption" // values: body
}
