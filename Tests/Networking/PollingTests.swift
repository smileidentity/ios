import XCTest
import Combine
@testable import SmileID

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

    func testPollingFunctionSuccess() {
        let mockJobStatusRequest = JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        let expectation = XCTestExpectation(description: "Polling completes successfully")
        MockHelper.shouldFail = false
        MockHelper.jobComplete = true
        mockService.poll(
                service: mockService,
                request: { self.mockService.getJobStatus(request: mockJobStatusRequest) },
                isComplete: { $0.jobComplete },
                interval: 1.0,
                numAttempts: 3
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("Polling failed with error: \(error)")
                    case .finished:
                        expectation.fulfill()
                    }
                },
                receiveValue: { response in
                    XCTAssert(response.jobComplete, "Job is complete")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 10.0)
    }

    func testPollingFunction_ErrorDuringPolling() {
        let mockJobStatusRequest = JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )

        let expectation = XCTestExpectation(description: "Polling fails due to an error")
        MockHelper.shouldFail = true
        MockHelper.jobComplete = false
        mockService.poll(
                service: mockService,
                request: { self.mockService.getJobStatus(request: mockJobStatusRequest) },
                isComplete: {
                    print("is complete \($0.jobComplete)")
                    return $0.jobComplete
                },
                interval: 0.1,
                numAttempts: 5
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        expectation.fulfill()
                    case .finished:
                        XCTFail("Polling should have failed due to an error")
                    }
                },
                receiveValue: { response in
                    XCTFail("No response should be received b/c an error occurs at first attempt")
                })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testPollingFunction_MaxAttemptsReached() {
        let mockJobStatusRequest = JobStatusRequest(
            userId: "",
            jobId: "",
            includeImageLinks: true,
            includeHistory: true,
            partnerId: "",
            timestamp: "",
            signature: ""
        )
        let expectation = XCTestExpectation(
            description: "Polling fails due to reaching the maximum number of attempts"
        )

        MockHelper.shouldFail = false
        MockHelper.jobComplete = false
        mockService.poll(
                service: mockService,
                request: { self.mockService.getJobStatus(request: mockJobStatusRequest) },
                isComplete: { $0.jobComplete },
                interval: 0.1,
                numAttempts: 5
            )
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        if error.localizedDescription == SmileIDError.jobStatusTimeOut.localizedDescription {
                            expectation.fulfill()
                        }
                    case .finished:
                        XCTFail("Polling should have failed due to reaching the maximum number of attempts")
                    }
                },
                receiveValue: { response in
                    XCTAssertFalse(response.jobComplete, "Job is not complete")
                })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }
}
