import AVFoundation
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

    override func setUp() {
        super.setUp()
        // initialise mocks
        mockResultDelegate = MockSmartSelfieResultDelegate()
        mockFaceValidatorDelegate = MockFaceValidatorDelegate()

        stubCameraManager = StubCameraManager()
        mockFaceValidator = MockFaceValidator()
        mockFaceDetector = MockFaceDetector()

        selfieViewModel = SelfieViewModelV2(
            cameraManager: stubCameraManager,
            faceDetector: mockFaceDetector,
            faceValidator: mockFaceValidator,
            livenessCheckManager: StubLivenessManager(),
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
        super.tearDown()
    }

    func testBasics() {
        selfieViewModel
            .perform(
                action: .windowSizeDetected(
                    .zero,
                    .init(top: 0, leading: 0, bottom: 0, trailing: 0)
                )
            )
        selfieViewModel.perform(action: .onViewAppear)

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

    func setLayoutGuideFrame(with frame: CGRect) {
        // set layout guide
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
