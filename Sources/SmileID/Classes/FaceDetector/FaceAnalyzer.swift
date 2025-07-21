import ARKit
import CoreGraphics
import Foundation
import Vision

/// Keys used by UI to look up localized instruction strings.
enum CaptureDirective: String {
  case start = "Instructions.Start"
  case unableToDetectFace = "Instructions.UnableToDetectFace"
  case multipleFaces = "Instructions.MultipleFaces"
  case putFaceInOval = "Instructions.PutFaceInOval"
  case moveCloser = "Instructions.MoveCloser"
  case moveFarther = "Instructions.MoveFarther"
  case quality = "Instructions.Quality"
  case smile = "Instructions.Smile"
  case capturing = "Instructions.Capturing"
}

// MARK: - Protocol

protocol FaceAnalyzerType {
  func analyze(
    _ buffer: CVPixelBuffer,
    elapsed: TimeInterval,
    livenessCount: Int,
    isSmiling: Bool,
    completion: @escaping (FaceAnalyzer.Result) -> Void)
}

class FaceAnalyzer: FaceAnalyzerType {
  // MARK: - Result

  enum Result {
    case needsDirective(CaptureDirective)
    case captureLiveness(CGImagePropertyOrientation)
    case captureSelfie(CGImagePropertyOrientation)
  }

  // MARK: - Constants

  private enum Constants {
    static let intraImageMinDelay: TimeInterval = 0.35
    static let noFaceResetDelay: TimeInterval = 3
    static let faceCaptureQualityThreshold: Float = 0.25
    static let minFaceCenteredThreshold = 0.1
    static let maxFaceCenteredThreshold = 0.9
    static let minFaceAreaThreshold = 0.125
    static let maxFaceAreaThreshold = 0.25
    static let faceRotationThreshold = 0.03
    static let faceRollThreshold = 0.025 // roll has a smaller range than yaw
    static let numLivenessImages = 7
    static var numTotalSteps: Int { numLivenessImages + 1 } // numLivenessImages + 1 selfie image
    static let livenessImageSize = 320
    static let selfieImageSize = 640
  }

  private let faceDetector = FaceDetector()

  // Store last pose so we can ensure rotation diversity.
  private var previousHeadRoll = Double.infinity
  private var previousHeadPitch = Double.infinity
  private var previousHeadYaw = Double.infinity

  // MARK: FaceAnalyzerType

  func analyze(
    _ buffer: CVPixelBuffer,
    elapsed _: TimeInterval,
    livenessCount: Int,
    isSmiling: Bool,
    completion: @escaping (Result) -> Void
  ) {
    do {
      try faceDetector.detect(imageBuffer: buffer) {
        [weak self] request,
          error in
        guard let self else { return }

        if let error {
          print("[FaceAnalyzer] Vision error: \(error)")
          completion(.needsDirective(.unableToDetectFace))
          return
        }

        guard let faces = request.results as? [VNFaceObservation] else { return }
        self.process(
          faces: faces,
          buffer: buffer,
          livenessCount: livenessCount,
          isSmiling: isSmiling,
          completion: completion
        )
      }
    } catch {
      print("[FaceAnalyzer] detection error: \(error)")
      completion(.needsDirective(.unableToDetectFace))
    }
  }

  // MARK: - Internal Rules

  private func process(
    faces: [VNFaceObservation],
    buffer _: CVPixelBuffer,
    livenessCount: Int,
    isSmiling: Bool,
    completion: @escaping (Result) -> Void
  ) {
    // Presence / mutliplicity
    guard !faces.isEmpty else {
      completion(.needsDirective(.unableToDetectFace))
      return
    }
    guard faces.count == 1 else {
      completion(.needsDirective(.multipleFaces))
      return
    }

    let face = faces[0]

    // Bounds / Centering
    guard isFaceCentered(face.boundingBox) else {
      completion(.needsDirective(.putFaceInOval))
      return
    }

    // Size
    let ratio = face.boundingBox.width * face.boundingBox.height
    switch ratio {
    case ..<Constants.minFaceAreaThreshold:
      completion(.needsDirective(.moveCloser))
      return
    case Constants.maxFaceAreaThreshold...:
      completion(.needsDirective(.moveFarther))
      return
    default: break
    }

    // Quality
    if let quality = face.faceCaptureQuality,
       quality < Constants.faceCaptureQualityThreshold {
      completion(.needsDirective(.quality))
      return
    }

    // Smile after halfway point
    if livenessCount > Constants.numLivenessImages / 2, !isSmiling {
      completion(.needsDirective(.smile))
      return
    }

    // Rotation diversity
    guard hasRotated(face) else {
      completion(.needsDirective(.capturing))
      return
    }

    // Decide capture type
    let orientation: CGImagePropertyOrientation = .right // mirror front camera
    if livenessCount < Constants.numLivenessImages {
      completion(.captureLiveness(orientation))
    } else {
      completion(.captureSelfie(orientation))
    }
  }

  // MARK: - Helpers

  private func isFaceCentered(_ boundingBox: CGRect) -> Bool {
    boundingBox.minX >= Constants.minFaceCenteredThreshold &&
      boundingBox.minY >= Constants.minFaceCenteredThreshold &&
      boundingBox.maxX <= Constants.maxFaceCenteredThreshold &&
      boundingBox.maxY <= Constants.maxFaceCenteredThreshold
  }

  private func hasRotated(_ face: VNFaceObservation) -> Bool {
    let roll = face.roll?.doubleValue ?? 0
    let yaw = face.yaw?.doubleValue ?? 0
    var pitch = 0.0
    if #available(iOS 15.0, *) { pitch = face.pitch?.doubleValue ?? 0 }

    let changed =
      abs(roll - previousHeadRoll) > Constants.faceRollThreshold ||
      abs(yaw - previousHeadYaw) > Constants.faceRotationThreshold ||
      abs(pitch - previousHeadPitch) > Constants.faceRotationThreshold

    previousHeadRoll = roll
    previousHeadYaw = yaw
    previousHeadYaw = yaw

    return changed
  }
}
