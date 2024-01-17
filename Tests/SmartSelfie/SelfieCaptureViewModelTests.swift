import XCTest
import Combine
@testable import SmileID

final class SelfieCaptureViewModelTests: XCTestCase {
    let mockDependency = DependencyContainer()
    let mockService = MockSmileIdentityService()
    let mockResult = MockResultDelegate()
    var subscribers = Set<AnyCancellable>()

    override func setUpWithError() throws {
        let config = Config(
            partnerId: "id",
            authToken: "token",
            prodUrl: "url", testUrl: "url",
            prodLambdaUrl: "url",
            testLambdaUrl: "url"
        )
        SmileID.initialize(config: config)
        DependencyAutoResolver.set(resolver: mockDependency)
        mockDependency.register(SmileIDServiceable.self, creation: {
            self.mockService
        })
    }

//    func testPublishedValuesAreExpectedValuesAtInit() {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        XCTAssertFalse(viewModel.isAcceptableRoll)
//        XCTAssertFalse(viewModel.isAcceptableYaw)
//        // XCTAssertFalse(viewModel.isAcceptableQuality)
//        XCTAssertFalse(viewModel.hasDetectedValidFace)
//        XCTAssertEqual(viewModel.isAcceptableBounds, .unknown)
//        XCTAssertEqual(viewModel.faceDetectionState, .noFaceDetected)
//        XCTAssertEqual(viewModel.faceGeometryState, .faceNotFound)
//        XCTAssertEqual(viewModel.faceQualityState, .faceNotFound)
//    }
//
//    func testPerformActionWhenSceneIsUnstablePublishesExpectedValues() throws {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        viewModel.perform(action: .sceneUnstable)
//        let expectation = XCTestExpectation()
//        XCTAssertEqual(viewModel.faceDetectionState, .sceneUnstable)
//        viewModel.$directive
//            .sink { value in
//                XCTAssertEqual(value, "Instructions.Start")
//                expectation.fulfill()
//            }
//            .store(in: &subscribers)
//        wait(for: [expectation], timeout: 1)
//    }
//
//    func testPerformActionWhenNoFaceIsDetectedPublishesExpectedValues() throws {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        viewModel.perform(action: .noFaceDetected)
//        XCTAssertEqual(viewModel.faceDetectionState, .noFaceDetected)
//        XCTAssertEqual(viewModel.faceGeometryState, .faceNotFound)
//        XCTAssertEqual(viewModel.faceQualityState, .faceNotFound)
//
//        let expectation = XCTestExpectation()
//        viewModel.$directive
//            .sink { value in
//                XCTAssertEqual(value, "Instructions.Start")
//                expectation.fulfill()
//            }
//            .store(in: &subscribers)
//        wait(for: [expectation], timeout: 1)
//    }
//
//    func testPerformActionWhenMultipleFacesDetectedPublishesExpectedValues() throws {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        viewModel.perform(action: .multipleFacesDetected)
//        XCTAssertEqual(viewModel.faceDetectionState, .multipleFacesDetected)
//
//        let expectation = XCTestExpectation()
//        viewModel.$directive
//            .sink { _ in
////                XCTAssertEqual(value, "Instructions.MultipleFaces")
//                expectation.fulfill()
//            }
//            .store(in: &subscribers)
//        wait(for: [expectation], timeout: 1)
//    }
//
//    func testPerformActionWhenFaceDetectedPublishesExpectedValues() throws {
//        let frameLayout = CGRect(origin: .zero, size: CGSize(width: 300, height: 300))
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        viewModel.faceLayoutGuideFrame = frameLayout
//        let boundingRect = CGRect(
//            origin: .zero,
//            size: CGSize(width: 0.5 * frameLayout.size.width, height: 0.5 * frameLayout.size.width)
//        )
//        let faceGeometryModel = FaceGeometryModel(
//            boundingBox: boundingRect,
//            roll: 0.4,
//            yaw: 0.1
//        )
//        viewModel.perform(action: .faceObservationDetected(faceGeometryModel))
//    }
//
//    func testSubmitFunctionPublishesExpectedValuesOnSuccess() {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        viewModel.selfieImage = Data()
//
//        MockHelper.shouldFail = false
//        let expectation = XCTestExpectation()
//        viewModel.smartSelfieResultDelegate = mockResult
//        viewModel.submit()
//        viewModel.$processingState
//            .sink { value in
//                switch value {
//                case .complete:
//                    expectation.fulfill()
//                default:
//                    break
//                }
//            }
//            .store(in: &subscribers)
//        wait(for: [expectation], timeout: 3)
//    }
//
//    func testSubmitFunctionPublishesErrorOnFailure() {
//        let viewModel = SelfieCaptureViewModel(userId: "testUserId", jobId: "jobId", isEnroll: true, allowNewEnroll: false)
//        MockHelper.shouldFail = true
//        let expectation = XCTestExpectation()
//        viewModel.smartSelfieResultDelegate = mockResult
//        viewModel.submit()
//        viewModel.$processingState
//            .sink { value in
//                switch value {
//                case .error:
//                    expectation.fulfill()
//                default:
//                    break
//                }
//            }
//            .store(in: &subscribers)
//        wait(for: [expectation], timeout: 3)
//    }
}
