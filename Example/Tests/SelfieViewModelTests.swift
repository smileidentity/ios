import XCTest

@testable import SmileID

final class SelfieViewModelTests: XCTestCase {
    
    var selfieViewModel: SelfieViewModelV2!
    var mockResultDelegate: MockSmartSelfieResultDelegate!
    var mockFaceValidatorDelegate: MockFaceValidatorDelegate!
    
    override func setUp() {
        super.setUp()
        mockResultDelegate = MockSmartSelfieResultDelegate()
        mockFaceValidatorDelegate = MockFaceValidatorDelegate()
//        selfieViewModel = SelfieViewModelV2(
//            isEnroll: true,
//            userId: "testuser",
//            jobId: "testjob",
//            allowNewEnroll: true,
//            skipApiSubmission: false,
//            extraPartnerParams: [:],
//            useStrictMode: true,
//            onResult: mockResultDelegate,
//            localMetadata: LocalMetadata()
//        )
    }
    
    override func tearDown() {
        selfieViewModel = nil
        mockResultDelegate = nil
        super.tearDown()
    }
}

// MARK: Mocks
class MockSmartSelfieResultDelegate: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: URL, livenessImages: [URL], apiResponse: SmartSelfieResponse?) {
    }

    func didError(error: any Error) {
    }
}
