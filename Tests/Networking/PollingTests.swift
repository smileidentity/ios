import XCTest
import Combine
@testable import SmileID

final class PollingTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = []
    let mockDependency = DependencyContainer()
    let mockService = MockSmileIdentityService()

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

    func testPollingFunctionSuccess() {
        let mockJobStatusRequest = JobStatusRequest(userId: "",
                                                    jobId: "",
                                                    includeImageLinks: true,
                                                    includeHistory: true,
                                                    partnerId: "",
                                                    timestamp: "",
                                                    signature: "")
        let expectation = XCTestExpectation(description: "Polling completes successfully")
        MockHelper.shouldFail = false
        mockService.poll(service: mockService,
                         request: { self.mockService.getJobStatus(request: mockJobStatusRequest) },
                         isComplete: { $0.jobComplete },
                         interval: 1.0,
                         numAttempts: 3)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                XCTFail("Polling failed with error: \(error)")
            case .finished:
                expectation.fulfill()
            }
        }, receiveValue: { response in
            XCTAssert(response.jobComplete, "Job is complete")
        })
        .store(in: &cancellables)

        // Assert
        wait(for: [expectation], timeout: 10.0)

    }


    func testPollingFunction_ErrorDuringPolling() {
        let mockJobStatusRequest = JobStatusRequest(userId: "",
                                                    jobId: "",
                                                    includeImageLinks: true,
                                                    includeHistory: true,
                                                    partnerId: "",
                                                    timestamp: "",
                                                    signature: "")

        let expectation = XCTestExpectation(description: "Polling fails due to an error")
        MockHelper.shouldFail = true
        // Act
        mockService.poll(service: mockService,
                         request: { self.mockService.getJobStatus(request: mockJobStatusRequest) },
                         isComplete: { $0.jobComplete },
                         interval: 1,
                         numAttempts: 5)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                //XCTAssertEqual(error.localizedDescription, "Some error occurred")
                expectation.fulfill()
            case .finished:
                XCTFail("Polling should have failed due to an error")
            }
        }, receiveValue: { response in
            XCTFail("No response should be received because an error occurs at the first attempt")
        })
        .store(in: &cancellables)

        // Assert
        wait(for: [expectation], timeout: 10.0)
    }

    func testPollingFunction_MaxAttemptsReached() {
        // Arrange
        let mockJobStatusRequest = JobStatusRequest(userId: "",
                                                    jobId: "",
                                                    includeImageLinks: true,
                                                    includeHistory: true,
                                                    partnerId: "",
                                                    timestamp: "",
                                                    signature: "")
        // Configure the mock service to return the mock response at all attempts
        let expectation = XCTestExpectation(description: "Polling fails due to reaching the maximum number of attempts")

        // Act
        mockService.poll(service: mockService,
                         request: { self.mockService.getJobStatus( request: mockJobStatusRequest ) },
             isComplete: { $0.jobComplete },
             interval: 0.1,
             numAttempts: 5)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Reached the maximum number of attempts")
                expectation.fulfill()
            case .finished:
                XCTFail("Polling should have failed due to reaching the maximum number of attempts")
            }
        }, receiveValue: { response in
            XCTAssertFalse(response.jobComplete, "Job is not complete")
        })
        .store(in: &cancellables)

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

}

