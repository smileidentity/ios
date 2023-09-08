import Foundation
import Vision
import CoreImage

protocol TextDetectionDelegate: AnyObject {
    func noTextDetected()
    func onTextDetected()
}

class TextDetector {
    let sequenceHandler = VNSequenceRequestHandler()
    weak var delegate: TextDetectionDelegate?

    func detectText(buffer: CVPixelBuffer) {
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        try? sequenceHandler.perform([request], on: buffer)
    }

    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            delegate?.noTextDetected()
            return
        }

        let recognisedString = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }

        if recognisedString.isEmpty {
            delegate?.noTextDetected()
        } else {
            delegate?.onTextDetected()
        }
    }
}
