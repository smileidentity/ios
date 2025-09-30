import Foundation

struct DocumentDetectionResult {
  let boundingBox: CGRect
  let corners: [CGPoint] // For perspective correction
  let documentType: DocumentType
  let confidence: Float
}

enum DocumentType {
  case passport
  case idCard
  case driversLicense
  case unknown
}
