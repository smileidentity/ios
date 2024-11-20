import AVFoundation
import Combine
import XCTest

@testable import SmileID

final class SelfieViewModelTests: XCTestCase {

    var selfieViewModel: SelfieViewModelV2!
    var mockResultDelegate: MockSmartSelfieResultDelegate!
    var mockFaceValidatorDelegate: MockFaceValidatorDelegate!
    var mockFaceValidator: MockFaceValidator!
    var mockFaceDetector: MockFaceDetector!

    override func setUp() {
        super.setUp()
        mockResultDelegate = MockSmartSelfieResultDelegate()
        mockFaceValidatorDelegate = MockFaceValidatorDelegate()
        selfieViewModel = SelfieViewModelV2(
            cameraManager: StubCameraManager(),
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

        // when view appears:
        // windowSizeDetected is called
        // faceLayoutGuideFrame of mockFaceValidator should be set.

        // mockFaceDetector should analyze pixel buffer and return face observation

        // mockFaceValidator should also return some results

        // check the results from mockFaceValidator is good,
        // selfie should be captured and there should be a URL for selfieImage set.
        // which means we have to mock LocalStorage which is a singleton

        // liveness check manager should now be initiated
        // check that a current task is set.
        // if no progress is emitted from liveness manager after the timeout then
        // check that animation has started playing for that task
        // now let the progress be emitted
        // check that liveness images are captured when task is completed
        // when timeout check how many images are captured before submitting to verify the logic of capturing remaining random liveness images.

        // check when we send job processing done
        // cameramanager pause should be called.

        // check if all tasks are complete
        // check that submission starts
        // mock the submission manager:
        // when it returns success: check the selfie capture state
        // and when it returns failure check the state again

        // check when there is a timeout from liveness manager
        // check that submission happens

        // others
        // check that alert shows when camera permission denied
        // and it doesn't show when permission is granted.

        // mock UIApplication
        // check that it called open url when permission is denied and directed to settings.

        // XCTAssertEqual(mockFaceValidator., <#T##expression2: Equatable##Equatable#>)
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
