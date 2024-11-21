import AVFoundation
import SwiftUICore
import Combine
import XCTest

@testable import SmileID

final class SelfieViewModelTests: XCTestCase {

    var selfieViewModel: SelfieViewModelV2!

    // mock delegates
    var mockResultDelegate: MockSmartSelfieResultDelegate!
    var mockFaceValidatorDelegate: MockFaceValidatorDelegate!

    // mock dependencies
    var stubCameraManager: StubCameraManager!
    var mockFaceValidator: MockFaceValidator!
    var mockFaceDetector: MockFaceDetector!
    var stubLivenessManager: StubLivenessManager!

    override func setUp() {
        super.setUp()
        // initialise mocks
        mockResultDelegate = MockSmartSelfieResultDelegate()
        mockFaceValidatorDelegate = MockFaceValidatorDelegate()

        stubCameraManager = StubCameraManager()
        mockFaceValidator = MockFaceValidator()
        mockFaceDetector = MockFaceDetector()
        stubLivenessManager = StubLivenessManager()

        selfieViewModel = SelfieViewModelV2(
            cameraManager: stubCameraManager,
            faceDetector: mockFaceDetector,
            faceValidator: mockFaceValidator,
            livenessCheckManager: stubLivenessManager,
            delayTimer: MockTimer(),
            dispatchQueue: DispatchQueueMock(),
            selfieCaptureConfig: SelfieCaptureConfig(
                isEnroll: true,
                userId: "testuser",
                jobId: "testjob",
                allowNewEnroll: false,
                skipApiSubmission: false,
                useStrictMode: true,
                allowAgentMode: false,
                showAttribution: true,
                showInstructions: true,
                extraPartnerParams: [:]
            ),
            onResult: mockResultDelegate,
            localMetadata: LocalMetadata()
        )
    }

    override func tearDown() {
        selfieViewModel = nil
        mockResultDelegate = nil
        mockFaceValidatorDelegate = nil
        
        mockFaceDetector = nil
        mockFaceValidator = nil
        stubCameraManager = nil
        stubLivenessManager = nil
        super.tearDown()
    }

    func testFrameLayoutGuide() {
        let windowSize = CGSize(width: 393, height: 852)
        let safeArea = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        selfieViewModel.perform(action: .windowSizeDetected(windowSize, safeArea))
        selfieViewModel.perform(action: .onViewAppear)
        
        XCTAssertEqual(
            mockFaceValidator.faceGuideFrame,
            CGRect(x: 71.5, y: 100, width: 250, height: 350)
        )
        XCTAssertEqual(selfieViewModel.selfieCaptureState, .capturingSelfie)
    }
}

// MARK: Mocks & Stubs
class MockFaceDetector: FaceDetectorProtocol {
    weak var viewDelegate: FaceDetectorViewDelegate?

    weak var resultDelegate: FaceDetectorResultDelegate?

    func processImageBuffer(_ imageBuffer: CVPixelBuffer) {
    }
}

class MockFaceValidator: FaceValidatorProtocol {
    weak var delegate: FaceValidatorDelegate?
    
    var faceGuideFrame: CGRect = .zero

    func setLayoutGuideFrame(with frame: CGRect) {
        faceGuideFrame = frame
    }

    func validate(
        faceGeometry: FaceGeometryData, selfieQuality: SelfieQualityData, brightness: Int,
        currentLivenessTask: LivenessTask?
    ) {
        // perform validation
    }
}

class MockSmartSelfieResultDelegate: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: URL, livenessImages: [URL], apiResponse: SmartSelfieResponse?) {
    }

    func didError(error: any Error) {
    }
}

class StubLivenessManager: LivenessCheckManager {
    var didInitiateLivenessCheck: Bool = false

    override func initiateLivenessCheck() {
        didInitiateLivenessCheck = true
    }

    override func processFaceGeometry(_ faceGeometry: FaceGeometryData) {
        // process face geometry here
    }
}

class StubCameraManager: CameraManager {
    var cameraSwitched: Bool = false
    var sessionPaused: Bool = false

    private var cancellable: AnyCancellable?
    @Published var buffer: CVPixelBuffer?

    init() {
        super.init(orientation: .portrait)
    }

    override var sampleBufferPublisher: Published<CVPixelBuffer?>.Publisher {
        $buffer
    }

    override func switchCamera(to position: AVCaptureDevice.Position) {
        cameraSwitched.toggle()
    }

    override func pauseSession() {
        sessionPaused = true
    }
}
