import Foundation
import Vision
import CoreImage

class TextDetector {
    private let sequenceHandler = VNSequenceRequestHandler()

    func detectText(buffer: CVPixelBuffer, onDetectionResult: @escaping (_ hasText: Bool) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                onDetectionResult(false)
                return
            }
            if let error = error {
                print("Text Detection Error: \(error)")
            }

            let recognisedString = observations.compactMap { $0.topCandidates(1).first?.string }

            onDetectionResult(!recognisedString.isEmpty)
        }
        try? sequenceHandler.perform([request], on: buffer)
    }
}
