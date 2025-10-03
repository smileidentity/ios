class FaceDetectorAnalyzer: Analyzer {
    typealias Input = AnalyzerInput
    typealias State = IdentityScanState
    typealias Output = AnalyzerOutput


    private let minDetectionConfidence: Float

    init(minDetectionConfidence: Float) {
        self.minDetectionConfidence = minDetectionConfidence
    }

    /**
     * We will run face detection here, using MediaPipe and pass back the output
     *
     * We can easily swap out implementations here for other analyzers like CoreML
     */
    func analyze(data: AnalyzerInput, state: IdentityScanState) async -> AnalyzerOutput {
        // Your face detection logic here - can now use Mediapipe or CoreML

        // Return FaceDetectorOutput
        return FaceDetectorOutput(
            faces: [], // Your detected faces array
            resultScore: 0.0 // Your confidence score
        )
    }

    // MARK: - Factory
    
    class Factory: AnalyzerFactory {
        typealias Input = AnalyzerInput
        typealias State = IdentityScanState
        typealias Output = AnalyzerOutput
        typealias AnalyzerType = FaceDetectorAnalyzer

        let minDetectionConfidence: Float

        init(minDetectionConfidence: Float) {
            self.minDetectionConfidence = minDetectionConfidence
        }

        func newInstance() async -> FaceDetectorAnalyzer? {
            FaceDetectorAnalyzer(
                minDetectionConfidence: minDetectionConfidence
            )
        }
    }

    // MARK: - Constants

    static let MODEL_NAME = "blaze_face_short_range.tflite"
}
