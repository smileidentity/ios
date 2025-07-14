import Vision

class ObjectDetector {
    private var requests = [VNRequest]()

    init() {
        setupVision()
    }

    private func setupVision() {
        guard let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") else { return }

        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    self?.completionHandler?([], error)
                    return
                }

                let detectedObjects = results.map { observation -> DetectedObject in
                    let label = observation.labels.first?.identifier ?? "Unknown"
                    let confidence = observation.confidence
                    let boundingBox = observation.boundingBox
                    return DetectedObject(label: label, confidence: confidence, boundingBox: boundingBox)
                }

                self?.completionHandler?(detectedObjects, nil)
            }
            objectRecognition.imageCropAndScaleOption = .scaleFill
            print("Juma success here")
            requests = [objectRecognition]
        } catch {
            // todo log this on sentry
            print("Vision setup error: \(error.localizedDescription)")
        }
    }

    private var completionHandler: (([DetectedObject], Error?) -> Void)?

    func detectObjects(
        in pixelBuffer: CVPixelBuffer,
        completion: @escaping ([DetectedObject], Error?) -> Void
    ) {
        print("Juma detectObjects \(pixelBuffer)")
        completionHandler = completion
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform(self.requests)
            } catch {
                completion([], error)
            }
        }
    }
}

struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
