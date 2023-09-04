import Foundation
import Vision
import CoreImage


class TextDetector {
    let sequenceHandler = VNSequenceRequestHandler()
    weak var model: DocumentCaptureViewModel?

    func detectText(buffer: CVPixelBuffer) {
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        try? sequenceHandler.perform([request], on: buffer)
    }

    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            model?.handleNoTextDetected()
            return
        }

        let recognisedString = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }

        if recognisedString.isEmpty {
            model?.handleNoTextDetected()
        } else {
            model?.handleTextDetected()
        }
    }
}
