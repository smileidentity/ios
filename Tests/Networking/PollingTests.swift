import XCTest
import Combine
@testable import SmileID

final class PollingTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = []
    let mockDependency = DependencyContainer()
    var mockService: MockSmileIDServiceable!
    let numAttempts = 5
    let jobStatusRequest = JobStatusRequest(
        userId: "userId",
        jobId: "jobId",
        includeImageLinks: true,
        includeHistory: true,
        partnerId: "partnerId",
        timestamp: "timestamp",
        signature: "signature"
    )

    override func setUp() {
        mockService = MockSmileIDServiceable.create()
        DependencyAutoResolver.set(resolver: mockDependency)
        mockDependency.register(SmileIDServiceable.self, creation: { self.mockService })
        initSdk()
    }

    override func tearDown() {
        mockService.verify()
    }

    func testPollingFunctionSuccess() async throws {
        // given
        let jobStatusResponse = JobStatusResponse(jobComplete: true)
        mockService.expect { $0.getJobStatus(request: self.jobStatusRequest) }
            .returning(just(jobStatusResponse))

        // when
        let response = try await mockService
            .pollJobStatus(request: self.jobStatusRequest, interval: 1, numAttempts: 3)
            .async()

        // then
        XCTAssert(response.jobComplete)
    }

    func testPollingFunction_ErrorDuringPolling() async throws {
        // given
        let knownError = SmileIDError.unknown("unknown")
        for _ in 1...numAttempts {
            mockService.expect { $0.getJobStatus(request: self.jobStatusRequest) }
                .returning(justError(knownError, JobStatusResponse.self))
        }

        // when
        await assertThrowsAsyncError(
            try await mockService.pollJobStatus(
                request: self.jobStatusRequest,
                interval: 0,
                numAttempts: numAttempts
            ).async()
        ) { error in
            // then
            XCTAssertEqual(knownError.localizedDescription, error.localizedDescription)
        }
    }

    func testPollingFunction_MaxAttemptsReached() async {
        // given
        let jobStatusResponse = JobStatusResponse(jobComplete: false)
        for _ in 1...numAttempts {
            mockService.expect { $0.getJobStatus(request: self.jobStatusRequest) }
                .returning(just(jobStatusResponse))
        }

        // when
        await assertThrowsAsyncError(
            try await mockService.pollJobStatus(
                request: self.jobStatusRequest,
                interval: 0,
                numAttempts: numAttempts
            ).async()
        ) { error in
            // then
            XCTAssertEqual(
                SmileIDError.jobStatusTimeOut.localizedDescription,
                error.localizedDescription
            )
        }
    }
}
