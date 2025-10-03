import Foundation

struct FaceValidationResult {
  let passed: Bool
  let checks: [ValidationCheck]
  let feedbackMessage: String
}
