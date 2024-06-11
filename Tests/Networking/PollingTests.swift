import Combine
@testable import SmileID
import XCTest

final class PollingTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    let mockDependency = DependencyContainer()
    let mockService = MockSmileIdentityService()

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

    override func tearDown() {
        super.tearDown()
        MockHelper.shouldFail = false
        MockHelper.jobComplete = true
    }

    func testPollJobStatus_Success<T: JobResult>(
        pollFunction: (JobStatusRequest, TimeInterval, Int) async throws -> JobStatusResponse<T>,
        expectedResponse: JobStatusResponse<T>,
        requestBuilder: () -> JobStatusRequest
    ) async {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3
        
        do {
            let response = try await pollFunction(request, interval, numAttempts)
            XCTAssertEqual(response.jobComplete, expectedResponse.jobComplete)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPollingFunction_ErrorDuringPolling(
        pollFunction: (JobStatusRequest, TimeInterval, Int) async throws -> JobStatusResponse<some JobResult>,
        requestBuilder: () -> JobStatusRequest
    ) async {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3

        let expectation = XCTestExpectation(description: "Polling fails due to an error")

        MockHelper.shouldFail = true
        MockHelper.jobComplete = false
        
        do {
            _ = try await pollFunction(request, interval, numAttempts)
            XCTFail("No response should be received b/c an error occurs at first attempt")
        } catch {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testPollingFunction_MaxAttemptsReached(
        pollFunction: (JobStatusRequest, TimeInterval, Int) async throws -> JobStatusResponse<some JobResult>,
        requestBuilder: () -> JobStatusRequest
    ) async {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3
        
        let expectation = XCTestExpectation(
            description: "Polling fails due to reaching the maximum number of attempts"
        )

        MockHelper.shouldFail = false
        MockHelper.jobComplete = false
        do {
            let response = try await pollFunction(request, interval, numAttempts)
            XCTAssertFalse(response.jobComplete, "Job is not complete")
        } catch {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testPollSmartSelfieJobStatus() async throws {
        let expectedResponse = SmartSelfieJobStatusResponse(jobComplete: true)
        let requestBuilder = { JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        }

        await testPollJobStatus_Success(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollDocumentVerificationJobStatus() async {
        let expectedResponse = DocumentVerificationJobStatusResponse(jobComplete: true)
        let requestBuilder = { JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        }

        await testPollJobStatus_Success(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollBiometricKycJobStatus() async {
        let expectedResponse = BiometricKycJobStatusResponse(jobComplete: true)
        let requestBuilder = { JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        }

        await testPollJobStatus_Success(
            pollFunction: mockService.pollBiometricKycJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollBiometricKycJobStatus,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollBiometricKycJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollEnhancedDocumentVerificationJobStatus() async {
        let expectedResponse = EnhancedDocumentVerificationJobStatusResponse(jobComplete: true)
        let requestBuilder = { JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        }

        await testPollJobStatus_Success(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )

        await testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )
    }
}
