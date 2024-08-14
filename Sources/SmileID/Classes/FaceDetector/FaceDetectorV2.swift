import AVFoundation
import Combine
import Vision

protocol FaceDetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FaceDetectorV2: NSObject {
    weak var viewDelegate: FaceDetectorDelegate?
    weak var viewModel: SelfieViewModelV2?
    
    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVImageBuffer?
    
    let imageProcessingQueue = DispatchQueue(
        label: "Image Processing Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate methods
extension FaceDetectorV2: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        currentFrameBuffer = imageBuffer
        
        do {
            try sequenceHandler.perform([detectFaceRectanglesRequest], on: imageBuffer, orientation: .leftMirrored)
        } catch {
            viewModel?.perform(action: .handleError(error))
        }
    }
}

// MARK: - Private methods
extension FaceDetectorV2 {
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard let viewModel = viewModel,
        let viewDelegate = viewDelegate else { return }

        guard let results = request.results as? [VNFaceObservation], 
                let result = results.first else {
            viewModel.perform(action: .noFaceDetected)
            return
        }

        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)

        let faceObservationModel = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0.0,
            yaw: result.yaw ?? 0.0
        )

        viewModel.perform(action: .faceObservationDetected(faceObservationModel))
    }
}

