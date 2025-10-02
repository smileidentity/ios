import Foundation
import MediaPipeTasksVision

final class MediaPipeFaceDetector: FaceDetecting {
  private let faceDetector: FaceDetector
  private let configuration: ModelConfiguration
  private var nextVideoTimestampMs: Int = 0

  init(configuration: ModelConfiguration) throws {
    guard let path = Bundle.main.path(
      forResource: "face_detection_model",
      ofType: "tflite"
    ) else {
      throw ModelError.modelLoadFailed(
        underlying: NSError(
          domain: "ModelPath",
          code: -1,
          userInfo: [
            NSLocalizedDescriptionKey: "face_detection_model.tflite not found"
          ]
        )
      )
    }
    let options = FaceDetectorOptions()
    options.baseOptions.modelAssetPath = path
    options.runningMode = .video
    options.minDetectionConfidence = 0.5

    self.faceDetector = try FaceDetector(options: options)
    self.configuration = configuration
  }

  func detectFaces(
    in buffer: CVPixelBuffer
  ) async throws -> [FaceDetectionResult] {
    // Convert CVPixelBuffer to MPImage
    let mpImage = try MPImage(pixelBuffer: buffer)

    // MediaPipe expects monotonically increasing timestamps when running in video mode.
    nextVideoTimestampMs += 1
    let timestampMs = nextVideoTimestampMs

    // Run detection synchronously using the video-frame API
    let result = try faceDetector.detect(
      videoFrame: mpImage,
      timestampInMilliseconds: timestampMs
    )

    // Convert MediaPipe results to our format
    let faces = result.detections.map { detection in
      convertToFaceResult(detection)
    }

    return faces
  }

  private func convertToFaceResult(
    _ detection: Detection
  ) -> FaceDetectionResult {
    let boundingBox = detection.boundingBox

    // Convert normalized coordinates
    let normalizedBox = CGRect(
      x: CGFloat(boundingBox.origin.x),
      y: CGFloat(boundingBox.origin.y),
      width: CGFloat(boundingBox.width),
      height: CGFloat(boundingBox.height)
    )

    return FaceDetectionResult(
      boundingBox: normalizedBox,
      landmarks: convertMediapipeLandmarks(detection.keypoints),
      trackingID: nil, // Find out how to get trackingID with mediapipe
      roll: nil,
      pitch: nil,
      yaw: nil,
      confidence: detection.categories.first?.score ?? 0
    )
  }

  private func convertMediapipeLandmarks(
    _ keypoints: [NormalizedKeypoint]?
  ) -> FaceLandmarks? {
    guard let keypoints else { return nil }

    // MediaPipe's face detection model returns keypoints in the following order:
    // right eye, left eye, nose tip, mouth center, right ear tragion, left ear tragion.
    let rightEyeIndex = 0
    let leftEyeIndex = 1
    let noseIndex = 2
    let mouthIndex = 3

    guard keypoints.count > mouthIndex else { return nil }

    func point(from keypoint: NormalizedKeypoint) -> CGPoint {
      // Each keypoint exposes its normalized 2D location as a CGPoint.
      keypoint.location
    }

    let rightEye = keypoints[rightEyeIndex]
    let leftEye = keypoints[leftEyeIndex]
    let nose = keypoints[noseIndex]
    let mouth = keypoints[mouthIndex]

    let candidates = [rightEye, leftEye, nose, mouth]
    guard candidates.allSatisfy({
      $0.location.x.isFinite && $0.location.y.isFinite
    }) else { return nil }

    return FaceLandmarks(
      leftEye: point(from: leftEye),
      rightEye: point(from: rightEye),
      nose: point(from: nose),
      mouth: point(from: mouth)
    )
  }
}
