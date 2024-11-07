import XCTest

@testable import SmileID

class FaceValidatorTests: XCTestCase {
    var faceValidator: FaceValidator!
    var mockDelegate: MockFaceValidatorDelegate!

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
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.1, passed: 0.9),
            brightness: 100,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertTrue(mockValidationResult.faceInBounds)
        XCTAssertTrue(mockValidationResult.hasDetectedValidFace)
        XCTAssertNil(mockValidationResult.userInstruction)
    }

    func testValidateWithFaceTooSmall() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 100, height: 100),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.1, passed: 0.9),
            brightness: 100,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertFalse(mockValidationResult.faceInBounds)
        XCTAssertFalse(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .moveCloser)
    }

    func testValidateWithFaceTooLarge() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 250, height: 250),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.1, passed: 0.9),
            brightness: 100,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertFalse(mockValidationResult.faceInBounds)
        XCTAssertFalse(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .moveBack)
    }
    func testValidWithFaceOffCentre() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 125, y: 164, width: 190, height: 190),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.1, passed: 0.9),
            brightness: 100,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertFalse(mockValidationResult.faceInBounds)
        XCTAssertFalse(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .headInFrame)
    }

    func testValidateWithPoorBrightness() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.1, passed: 0.9),
            brightness: 70,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertTrue(mockValidationResult.faceInBounds)
        XCTAssertFalse(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .goodLight)
    }

    func testValidateWithPoorSelfieQuality() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.6, passed: 0.4),
            brightness: 70,
            currentLivenessTask: nil
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertTrue(mockValidationResult.faceInBounds)
        XCTAssertFalse(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .goodLight)
    }

    func testValidateWithLivenessTask() {
        let faceGeometry = FaceGeometryData(
            boundingBox: CGRect(x: 65, y: 164, width: 190, height: 190),
            roll: 0.0,
            yaw: 0.0,
            pitch: 0.0,
            direction: .none
        )

        faceValidator.validate(
            faceGeometry: faceGeometry,
            selfieQuality: SelfieQualityData(failed: 0.3, passed: 0.7),
            brightness: 100,
            currentLivenessTask: .lookLeft
        )

        guard let mockValidationResult = mockDelegate.validationResult else {
            XCTFail("Validation result should not be nil")
            return
        }

        XCTAssertTrue(mockValidationResult.faceInBounds)
        XCTAssertTrue(mockValidationResult.hasDetectedValidFace)
        XCTAssertEqual(mockValidationResult.userInstruction, .lookLeft)
    }
}

class MockFaceValidatorDelegate: FaceValidatorDelegate {
    var validationResult: FaceValidationResult?

    func updateValidationResult(_ result: FaceValidationResult) {
        self.validationResult = result
    }
}
