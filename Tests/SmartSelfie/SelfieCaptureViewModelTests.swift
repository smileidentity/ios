import XCTest
import Combine
@testable import SmileID

final class SelfieCaptureViewModelTests: XCTestCase {
    let mockDependency = DependencyContainer()
    let mockService = MockSmileIdentityService()
    let mockResult = MockResultDelegate()
    var subscribers = Set<AnyCancellable>()

    override func setUpWithError() throws {
        let config = Config(partnerId: "id",
                            authToken: "token",
                            prodUrl: "url", testUrl: "url",
                            prodLambdaUrl: "url",
                            testLambdaUrl: "url")
        SmileID.initialize(config: config)
        DependencyAutoResolver.set(resolver: mockDependency)
        mockDependency.register(SmileIDServiceable.self, creation: {
            self.mockService
        })
    }

    func testPublishedValuesAreExpectedValuesAtInit() {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        XCTAssertFalse(viewModel.isAcceptableRoll)
        XCTAssertFalse(viewModel.isAcceptableYaw)
        XCTAssertFalse(viewModel.isAcceptableQuality)
        XCTAssertFalse(viewModel.hasDetectedValidFace)
        XCTAssertEqual(viewModel.isAcceptableBounds, .unknown)
        XCTAssertEqual(viewModel.faceDetectionState, .noFaceDetected)
        XCTAssertEqual(viewModel.faceGeometryState, .faceNotFound)
        XCTAssertEqual(viewModel.faceQualityState, .faceNotFound)
    }

    func testPerfomActionWhenSceneIsUnstablePublishesExpectedValues() throws {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        viewModel.perform(action: .sceneUnstable)
        let expectation = XCTestExpectation()
        viewModel.$faceDetectionState
            .dropFirst()
            .sink { value in
                XCTAssertEqual(value, .sceneUnstable)
                expectation.fulfill()
            }.store(in: &subscribers)
        wait(for: [expectation], timeout: 1)

    }

    func testPerformActionWhenNoFaceIsDectectedPublishesExpectedValues() throws {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        viewModel.perform(action: .noFaceDetected)
        let expectation = XCTestExpectation()
        Publishers.CombineLatest3(viewModel.$faceDetectionState,
                                  viewModel.$faceGeometryState,
                                  viewModel.$faceQualityState)
            .dropFirst()
            .sink { values in
                XCTAssertEqual(values.0, .noFaceDetected)
                XCTAssertEqual(values.1, .faceNotFound)
                XCTAssertEqual(values.2, .faceNotFound)
                expectation.fulfill()
            }
            .store(in: &subscribers)
        wait(for: [expectation], timeout: 1)

    }

    func testPerfomActionWhenMultipleFacesDetectedPublishesExpectedValues() throws {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        viewModel.perform(action: .multipleFacesDetected)
        let expectation = XCTestExpectation()
        viewModel.$faceDetectionState
            .dropFirst()
            .sink { value in
                XCTAssertEqual(value, .multipleFacesDetected)
                expectation.fulfill()
            }.store(in: &subscribers)
        wait(for: [expectation], timeout: 1)
    }

    func testPerformActionWhenFaceDectedPublishesExpectedValues() throws {
        let frameLayout = CGRect(origin: .zero, size: CGSize(width: 300, height: 300))
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        viewModel.faceLayoutGuideFrame = frameLayout
        let boundingRect = CGRect(origin: .zero,
                                  size: CGSize(width: 0.5*frameLayout.size.width,
                                               height: 0.5*frameLayout.size.width))
        let faceGeometryModel = FaceGeometryModel(boundingBox: boundingRect,
                                                  roll: 0.4,
                                                  yaw: 0.1)
        viewModel.perform(action: .faceObservationDetected(faceGeometryModel))
        let expectation = XCTestExpectation()
        Publishers.CombineLatest(viewModel.$faceDetectionState, viewModel.$faceGeometryState)
            .dropFirst()
            .sink { values in
                XCTAssertEqual(values.0, .faceDetected)
                expectation.fulfill()
            }.store(in: &subscribers)
        wait(for: [expectation], timeout: 1)
    }

    func testSubmitFunctionPublishesExpectedValuesOnSuccess() {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)

        MockHelper.shouldFail = false
        let expectation = XCTestExpectation()
        viewModel.captureResultDelegate = mockResult
        viewModel.submit()
        viewModel.$processingState
            .sink { value in
                switch value {
                case .success(let response):
                    XCTAssertTrue(response.jobSuccess)
                    expectation.fulfill()
                default:
                    break
                }
            }.store(in: &subscribers)
        wait(for: [expectation], timeout: 3)
    }

    func testSubmitFunctionPublishesErrorOnFailure() {
        let viewModel = SelfieCaptureViewModel(userId: "testuserid", jobId: "jobId", isEnroll: true)
        MockHelper.shouldFail = true
        let expectation = XCTestExpectation()
        viewModel.captureResultDelegate = mockResult
        viewModel.submit()
        viewModel.$processingState
            .sink { value in
                switch value {
                case .error:
                    expectation.fulfill()
                default:
                    break
                }
            }.store(in: &subscribers)
        wait(for: [expectation], timeout: 3)
    }
}
