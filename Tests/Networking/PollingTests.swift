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
        pollFunction: (JobStatusRequest, TimeInterval, Int) -> AnyPublisher<JobStatusResponse<T>, Error>,
        expectedResponse: JobStatusResponse<T>,
        requestBuilder: () -> JobStatusRequest
    ) {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3

        let expectation = XCTestExpectation(description: "Poll Job Status Success")
        pollFunction(request, interval, numAttempts)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
                expectation.fulfill()
            }, receiveValue: { response in
                XCTAssertEqual(response.jobComplete, expectedResponse.jobComplete)
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    func testPollingFunction_ErrorDuringPolling(
        pollFunction: (JobStatusRequest, TimeInterval, Int) -> AnyPublisher<JobStatusResponse<some JobResult>, Error>,
        requestBuilder: () -> JobStatusRequest
    ) {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3

        let expectation = XCTestExpectation(description: "Polling fails due to an error")
        MockHelper.shouldFail = true
        MockHelper.jobComplete = false

        pollFunction(request, interval, numAttempts)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expectation.fulfill()
                case .finished:
                    XCTFail("Polling should have failed due to an error")
                }
            }, receiveValue: { _ in
                XCTFail("No response should be received b/c an error occurs at first attempt")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollingFunction_MaxAttemptsReached(
        pollFunction: (JobStatusRequest, TimeInterval, Int) -> AnyPublisher<JobStatusResponse<some JobResult>, Error>,
        requestBuilder: () -> JobStatusRequest
    ) {
        let request = requestBuilder()
        let interval: TimeInterval = 1.0
        let numAttempts = 3

        let expectation = XCTestExpectation(
            description: "Polling fails due to reaching the maximum number of attempts"
        )

        MockHelper.shouldFail = false
        MockHelper.jobComplete = false
        pollFunction(request, interval, numAttempts)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        if error.localizedDescription == SmileIDError.jobStatusTimeOut.localizedDescription {
                            expectation.fulfill()
                        }
                    case .finished:
                        XCTFail("Polling should have failed due to reaching the maximum number of attempts")
                    }
                },
                receiveValue: { response in
                    XCTAssertFalse(response.jobComplete, "Job is not complete")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollSmartSelfieJobStatus() {
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

        testPollJobStatus_Success(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            requestBuilder: requestBuilder
        )

        testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollSmartSelfieJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollDocumentVerificationJobStatus() {
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

        testPollJobStatus_Success(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )

        testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollBiometricKycJobStatus() {
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

        testPollJobStatus_Success(
            pollFunction: mockService.pollBiometricKycJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollBiometricKycJobStatus,
            requestBuilder: requestBuilder
        )

        testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollBiometricKycJobStatus,
            requestBuilder: requestBuilder
        )
    }

    func testPollEnhancedDocumentVerificationJobStatus() {
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

        testPollJobStatus_Success(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            expectedResponse: expectedResponse,
            requestBuilder: requestBuilder
        )

        testPollingFunction_ErrorDuringPolling(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )

        testPollingFunction_MaxAttemptsReached(
            pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
            requestBuilder: requestBuilder
        )
    }
}
