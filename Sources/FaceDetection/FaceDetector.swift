import Foundation
import Vision
import CoreImage

class FaceDetector {
    var sequenceHandler = VNSequenceRequestHandler()
    weak var model: SelfieCaptureViewModel?
    var currentFrameBuffer: CVImageBuffer?


    func detect(imageBuffer: CVImageBuffer) {
        
        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        
        //Use most recent models or fallback to older versions
        if #available(iOS 14.0, *) {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2
        } else {
            detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision1
        }
        
        if #available(iOS 15.0, *) {
            let detectSegmentationRequest = VNGeneratePersonSegmentationRequest(completionHandler: detectedSegmentationRequest)
            detectSegmentationRequest.qualityLevel = .balanced
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3
            runSequenceHandler(with: [detectFaceRectanglesRequest, detectCaptureQualityRequest, detectSegmentationRequest],
                               imageBuffer: imageBuffer)
            return
        } else {
            detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision2
        }
        runSequenceHandler(with: [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                           imageBuffer: imageBuffer)
    }
    
    func detectSmile(imageBuffer: CVImageBuffer) {
        let image = CIImage(cvImageBuffer: imageBuffer)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let smileDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
        let faces = smileDetector.features(in: image)
        if let face = faces.first as? CIFaceFeature {
            if face.hasSmile {
                print("Smile detected")
            }
        }
    }
    
    func runSequenceHandler(with requests: [VNRequest],
                            imageBuffer: CVImageBuffer) {
        do {
            try sequenceHandler.perform(requests,
                                         on: imageBuffer,
                                         orientation: .leftMirrored)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension FaceDetector {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation],
              let result = results.first else {
            model?.perform(action: .noFaceDetected)
            return
        }
    }
    
    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard let model = model else {
            return
        }

        guard let results = request.results as? [VNFaceObservation],
              let result = results.first else {
            model.perform(action: .noFaceDetected)
            return
        }
        
        let faceQualityModel = FaceQualityModel(quality: result.faceCaptureQuality ?? 0)
        model.perform(action: .faceQualityObservationDetected(faceQualityModel))
    }
    
    func detectedSegmentationRequest(request: VNRequest, error: Error?) {
    //TODO: remove backfround isolating only the face
        guard let model = model,
              let results = request.results as? [VNPixelBufferObservation],
              let result = results.first,
              let currentFrameBuffer = currentFrameBuffer else {
            return
        }
    }
}
