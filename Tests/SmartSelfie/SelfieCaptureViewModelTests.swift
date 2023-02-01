import XCTest
import Combine
@testable import SmileIdentity

final class SelfieCaptureViewModelTests: XCTestCase {

    var subscribers = Set<AnyCancellable>()

    func testPublishedValuesAreExpectedValuesAtInit() {
        let viewModel = SelfieCaptureViewModel()
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
        let viewModel = SelfieCaptureViewModel()
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
        let viewModel = SelfieCaptureViewModel()
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
        let viewModel = SelfieCaptureViewModel()
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
        let viewModel = SelfieCaptureViewModel()
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
}
