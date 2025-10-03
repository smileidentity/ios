import Foundation

/// Validates face detection results against requirements
/// used by orchestration layer to provide user feedback
final class FaceValidationEngine {
  private let configuration: ModelConfiguration

  init(configuration: ModelConfiguration) {
    self.configuration = configuration
  }

  func validate(
    faces: [FaceDetectionResult],
    frameSize: CGSize
  ) -> FaceValidationResult {
    var checks: [ValidationCheck] = []

    // Check face count
    let countCheck = validateFaceCount(faces)
    checks.append(countCheck)

    guard let face = faces.first else {
      return FaceValidationResult(
        passed: false,
        checks: checks,
        feedbackMessage: "No face detected"
      )
    }

    // Check face size
    let sizeCheck = validateFaceSize(face, frameSize: frameSize)
    checks.append(sizeCheck)

    // Check face position
    let positionCheck = validateFacePosition(face, frameSize: frameSize)
    checks.append(positionCheck)

    let allPassed = checks.allSatisfy(\.passed)
    let messages = checks.filter { !$0.passed }.map(\.message)

    return FaceValidationResult(
      passed: allPassed,
      checks: checks,
      feedbackMessage: messages.first ?? "Face looks good"
    )
  }

  private func validateFaceCount(
    _ faces: [FaceDetectionResult]
  ) -> ValidationCheck {
    switch faces.count {
    case 0:
      return ValidationCheck(
        type: .faceCount,
        passed: false,
        value: 0,
        message: "No face detected"
      )
    case 1:
      return ValidationCheck(
        type: .faceCount,
        passed: true,
        value: 1,
        message: "Single face detected"
      )
    default:
      return ValidationCheck(
        type: .faceCount,
        passed: false,
        value: Double(faces.count),
        message: "Multiple faces detected"
      )
    }
  }

  private func validateFaceSize(
    _ face: FaceDetectionResult,
    frameSize _: CGSize
  ) -> ValidationCheck {
    let faceWidth = face.boundingBox.width

    if faceWidth < configuration.minFaceSize {
      return ValidationCheck(
        type: .faceSize,
        passed: false,
        value: Double(faceWidth),
        message: "Move closer"
      )
    }

    if faceWidth > configuration.maxFaceSize {
      return ValidationCheck(
        type: .faceSize,
        passed: false,
        value: Double(faceWidth),
        message: "Move back"
      )
    }

    return ValidationCheck(
      type: .faceSize,
      passed: true,
      value: Double(faceWidth),
      message: "Face size good"
    )
  }

  private func validateFacePosition(
    _ face: FaceDetectionResult,
    frameSize _: CGSize
  ) -> ValidationCheck {
    let faceCenterX = face.boundingBox.midX
    let faceCenterY = face.boundingBox.midY

    let frameCenterX: CGFloat = 0.5
    let frameCenterY: CGFloat = 0.5

    let distanceX = abs(faceCenterX - frameCenterX)
    let distanceY = abs(faceCenterY - frameCenterY)

    let maxDistance = configuration.facePositionTolenrance

    if distanceX > maxDistance {
      return ValidationCheck(
        type: .facePosition,
        passed: false,
        value: Double(distanceX),
        message: faceCenterX < frameCenterX ? "Move right" : "Move left"
      )
    }

    if distanceY > maxDistance {
      return ValidationCheck(
        type: .facePosition,
        passed: false,
        value: Double(distanceY),
        message: faceCenterY < frameCenterY ? "Move down" : "Move up"
      )
    }

    return ValidationCheck(
      type: .facePosition,
      passed: true,
      value: max(Double(distanceX), Double(distanceY)),
      message: "Position good"
    )
  }
}
