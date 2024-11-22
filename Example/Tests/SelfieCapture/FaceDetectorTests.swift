import Vision
import XCTest

@testable import SmileID

final class FaceDetectorTests: XCTestCase {

    var faceDetector: FaceDetectorV2!
    var viewDelegate: FaceDetectorViewDelegate!
    var resultDelegate: MockFaceDetectorResultDelegate!
    var mockSequenceHandler: MockVNSequenceRequestHandler!
    var mockImageRequestHandler: MockImageRequestHandler!
    var mockSelfieQualityDetector: MockSelfieQualityDetector!

    override func setUp() {
        super.setUp()
        resultDelegate = MockFaceDetectorResultDelegate()
        mockSequenceHandler = MockVNSequenceRequestHandler()
        mockImageRequestHandler = MockImageRequestHandler()
        mockSelfieQualityDetector = MockSelfieQualityDetector()

        faceDetector = FaceDetectorV2(
            sequenceHandler: mockSequenceHandler,
            imageRequestHandler: mockImageRequestHandler,
            selfieQualityDetector: mockSelfieQualityDetector
        )
        faceDetector.VNDetectFaceRectanglesRequestClass = SampleVNDetectFaceRectanglesRequest.self
        faceDetector.VNDetectFaceCaptureQualityRequestClass = SampleVNDetectFaceCaptureQualityRequest.self
        faceDetector.resultDelegate = resultDelegate
    }

    override func tearDown() {
        resultDelegate = nil
        faceDetector = nil
    }

    func testProcessImageBuffer_NoFaceDetected() {
        mockSequenceHandler.shouldReturnFace = false
        guard let imageBuffer = createTestImageBuffer(with: UIImage()) else {
            XCTFail("Image Buffer should not be nil")
            return
        }

        faceDetector.processImageBuffer(imageBuffer)

        XCTAssertEqual(
            resultDelegate.error as? FaceDetectorError,
            .noFaceDetected,
            "Expected failure error to be '.noFaceDetected'"
        )
    }
    
    func testProcessImageBuffer_FaceDetected() {
        mockSequenceHandler.shouldReturnFace = true
        mockImageRequestHandler.shouldReturnFace = true

        guard let imageBuffer = createTestImageBuffer(with: UIImage()) else {
            XCTFail("Image Buffer should not be nil")
            return
        }

        faceDetector.processImageBuffer(imageBuffer)
        
        XCTAssertTrue(
            resultDelegate.didDetectFaceCalled,
            "Expected 'didDetectFaceCalled' to be true"
        )
    }

    func testCropImageToFace_NoFaceDetected() {
        mockImageRequestHandler.shouldReturnFace = false
        let testImage = createTestUIImage()

        XCTAssertThrowsError(
            try faceDetector.cropImageToFace(testImage),
            "Expected 'cropImageToFace' to throw an error"
        ) { error in
            XCTAssertEqual(
                error as? FaceDetectorError,
                .noFaceDetected,
                "Expected error to be '.noFaceDetected'"
            )
        }
    }
    
    func testCalculateBrightness() {
        let testImage = createTestUIImage()
        let brightness = faceDetector.calculateBrightness(testImage)
        XCTAssertGreaterThan(brightness, 0, "Expected brightness to be greater than 0.")
        XCTAssertLessThan(brightness, 255, "Expected brightness to be greater than 0.")
    }

    private func createTestUIImage() -> UIImage? {
        guard let imagePath = Bundle(for: type(of: self))
            .path(forResource: "sample_selfie", ofType: "jpg") else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }

    private func createTestImageBuffer(with uiImage: UIImage?) -> CVPixelBuffer? {
        return uiImage?.pixelBuffer(width: 360, height: 640)
    }
}

// MARK: - Mocks and Stubs
class MockFaceDetectorResultDelegate: FaceDetectorResultDelegate {
    var didDetectFaceCalled = false
    var error: Error?

    func faceDetector(
        _ detector: FaceDetectorV2,
        didDetectFace faceGeometry: FaceGeometryData,
        withFaceQuality faceQuality: Float,
        selfieQuality: SelfieQualityData,
        brightness: Int
    ) {
        didDetectFaceCalled = true
    }

    func faceDetector(_ detector: FaceDetectorV2, didFailWithError error: Error) {
        self.error = error
    }
}

class MockFaceDetectorViewDelegate: FaceDetectorViewDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        return rect
    }
}

class SampleVNDetectFaceRectanglesRequest: VNDetectFaceRectanglesRequest {
    override var results: [VNFaceObservation]? {
        get { return _results }
        set { _results = newValue }
    }

    private var _results: [VNFaceObservation]?
}

class SampleVNDetectFaceCaptureQualityRequest: VNDetectFaceCaptureQualityRequest {
    override var results: [VNFaceObservation]? {
        get { return _results }
        set { _results = newValue }
    }
    private var _results: [VNFaceObservation]?
}

class MockVNSequenceRequestHandler: VNSequenceRequestHandlerProtocol {
    var shouldReturnFace = false

    func perform(_ requests: [VNRequest], on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) throws
    {
        // Assuming Sample BoundingBox has been converted to View's coordinate
        let sampleBoundingBox = CGRect(x: 65, y: 164, width: 174, height: 174)
        for request in requests {
            if let faceRequest = request as? SampleVNDetectFaceRectanglesRequest {
                faceRequest.results =
                    shouldReturnFace
                ? [VNFaceObservation(boundingBox: sampleBoundingBox)] : []
            } else if let qualityRequest = request as? SampleVNDetectFaceCaptureQualityRequest {
                qualityRequest.results =
                    shouldReturnFace
                ? [VNFaceObservation(boundingBox: sampleBoundingBox)] : []
            } else {
                XCTFail("VNRequest type is unknown")
            }
        }
    }
}

class MockImageRequestHandler: VNImageRequestHandlerProtocol {
    var shouldReturnFace = false

    func perform(_ requests: [VNRequest]) throws {
        // Sample BoundingBox in Vision request coordinates
        let sampleBoundingBox = CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5)
        for request in requests {
            if let faceRequest = request as? SampleVNDetectFaceRectanglesRequest {
                faceRequest.results =
                shouldReturnFace
                ? [VNFaceObservation(boundingBox: sampleBoundingBox)] : []
            }
        }
    }
}

class MockSelfieQualityDetector: SelfieQualityDetectorProtocol {
    func predict(imageBuffer: CVPixelBuffer) throws -> SelfieQualityData {
        return SelfieQualityData(failed: 0.1, passed: 0.9)
    }
}
