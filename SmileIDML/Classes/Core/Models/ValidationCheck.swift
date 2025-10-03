import Foundation

struct ValidationCheck {
  enum CheckType {
    case faceSize
    case facePosition
    case luminance
    case faceCount
  }

  let type: CheckType
  let passed: Bool
  let value: Double
  let message: String
}
