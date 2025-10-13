class DocumentDetectorAnalyzer: Analyzer {
  typealias Input = AnalyzerInput
  typealias State = IdentityScanState
  typealias Output = AnalyzerOutput

  private let minDetectionConfidence: Float

  init(minDetectionConfidence: Float) {
    self.minDetectionConfidence = minDetectionConfidence
  }

  /**
   * We will run document detection here, using MediaPipe and pass back the output
   *
   * We can easily swap out implementations here for other analyzers like CoreML
   */
  func analyze(data _: AnalyzerInput, state _: IdentityScanState) async -> AnalyzerOutput {
    // Your face detection logic here - can now use Mediapipe or CoreML

    // Return FaceDetectorOutput
    DocumentDetectorOutput(
      documents: [], // Your detected documents array
      resultScore: 0.0 // Your confidence score
    )
  }

  // MARK: - Factory

  class Factory: AnalyzerFactory {
    typealias Input = AnalyzerInput
    typealias State = IdentityScanState
    typealias Output = AnalyzerOutput
    typealias AnalyzerType = DocumentDetectorAnalyzer

    let minDetectionConfidence: Float

    init(minDetectionConfidence: Float) {
      self.minDetectionConfidence = minDetectionConfidence
    }

    func newInstance() -> DocumentDetectorAnalyzer? {
      DocumentDetectorAnalyzer(
        minDetectionConfidence: minDetectionConfidence
      )
    }
  }

  // MARK: - Constants

  static let MODEL_NAME = "document_detector.tflite"
}
