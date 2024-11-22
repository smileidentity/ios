import XCTest

@testable import SmileID

class FaceValidatorTests: XCTestCase {
    private var faceValidator: FaceValidator!
    private var mockDelegate: MockFaceValidatorDelegate!

    override func setUp() {
        super.setUp()
        faceValidator = FaceValidator()
        mockDelegate = MockFaceValidatorDelegate()
        faceValidator.delegate = mockDelegate
        let guideFrame: CGRect = .init(x: 30, y: 100, width: 250, height: 350)
        faceValidator.setLayoutGuideFrame(with: guideFrame)
    }

    override func tearDown() {
        faceValidator = nil
        mockDelegate = nil
        super.tearDown()
    }

    func testValidateWithValidFace() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            selfieQualityData: SelfieQualityData(failed: 0.1, passed: 0.9),
            brighness: 100
        )

        XCTAssertTrue(result.faceInBounds)
        XCTAssertTrue(result.hasDetectedValidFace)
        XCTAssertNil(result.userInstruction)
    }

    func testValidateWithFaceTooSmall() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 100, height: 100),
            selfieQualityData: SelfieQualityData(failed: 0.1, passed: 0.9),
            brighness: 100
        )

        XCTAssertFalse(result.faceInBounds)
        XCTAssertFalse(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .moveCloser)
    }

    func testValidateWithFaceTooLarge() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 250, height: 250),
            selfieQualityData: SelfieQualityData(failed: 0.1, passed: 0.9),
            brighness: 100
        )

        XCTAssertFalse(result.faceInBounds)
        XCTAssertFalse(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .moveBack)
    }

    func testValidWithFaceOffCentre() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 125, y: 164, width: 190, height: 190),
            selfieQualityData: SelfieQualityData(failed: 0.1, passed: 0.9),
            brighness: 100
        )

        XCTAssertFalse(result.faceInBounds)
        XCTAssertFalse(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .headInFrame)
    }

    func testValidateWithPoorBrightness() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            selfieQualityData: SelfieQualityData(failed: 0.1, passed: 0.9),
            brighness: 70
        )

        XCTAssertTrue(result.faceInBounds)
        XCTAssertFalse(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .goodLight)
    }

    func testValidateWithPoorSelfieQuality() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            selfieQualityData: SelfieQualityData(failed: 0.6, passed: 0.4),
            brighness: 70
        )

        XCTAssertTrue(result.faceInBounds)
        XCTAssertFalse(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .goodLight)
    }

    func testValidateWithLivenessTask() {
        let result = performValidation(
            faceBoundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            selfieQualityData: SelfieQualityData(failed: 0.3, passed: 0.7),
            brighness: 100,
            livenessTask: .lookLeft
        )

        XCTAssertTrue(result.faceInBounds)
        XCTAssertTrue(result.hasDetectedValidFace)
        XCTAssertEqual(result.userInstruction, .lookLeft)
    }
}

// MARK: - Helpers
extension FaceValidatorTests {
    func performValidation(
        faceBoundingBox: CGRect,
        selfieQualityData: SelfieQualityData,
        brighness: Int,
        livenessTask: LivenessTask? = nil
    ) -> FaceValidationResult {
        let faceGeometry = FaceGeometryData(
            boundingBox: faceBoundingBox,
            roll: 0,
            yaw: 0,
            pitch: 0,
            direction: .none
        )
        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: selfieQualityData,
            brightness: brighness,
            currentLivenessTask: livenessTask
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return FaceValidationResult(userInstruction: nil, hasDetectedValidFace: false, faceInBounds: false)
        }
        return mockValidationResult
    }
}

// MARK: - Mocks
class MockFaceValidatorDelegate: FaceValidatorDelegate {
    var validationResult: FaceValidationResult?

    func updateValidationResult(_ result: FaceValidationResult) {
        self.validationResult = result
    }
}
