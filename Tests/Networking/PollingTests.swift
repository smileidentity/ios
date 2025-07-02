@testable import SmileID
import XCTest

final class PollingTests: XCTestCase {
  let mockDependency = DependencyContainer()
  let mockService = MockSmileIdentityService()

  override func setUpWithError() throws {
    let config = Config(
      partnerId: "id",
      authToken: "token",
      prodLambdaUrl: "url",
      testLambdaUrl: "url")
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
    pollFunction: @escaping (JobStatusRequest, TimeInterval, Int)
    async throws -> AsyncThrowingStream<JobStatusResponse<T>, Error>,
    expectedResponse: JobStatusResponse<T>,
    requestBuilder: () -> JobStatusRequest
  ) async throws {
    let request = requestBuilder()
    let interval: TimeInterval = 1.0
    let numAttempts = 3

    let stream = try await pollFunction(request, interval, numAttempts)

    do {
      for try await response in stream where response.jobComplete {
        XCTAssertEqual(response.jobComplete, expectedResponse.jobComplete)
        return
      }
      XCTFail("Stream completed without a jobComplete response")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testPollingFunction_ErrorDuringPolling(
    pollFunction: @escaping (JobStatusRequest, TimeInterval, Int)
    async throws -> AsyncThrowingStream<JobStatusResponse<some JobResult>, Error>,
    requestBuilder: () -> JobStatusRequest
  ) async {
    let request = requestBuilder()
    let interval: TimeInterval = 1.0
    let numAttempts = 3

    MockHelper.shouldFail = true
    MockHelper.jobComplete = false

    do {
      let stream = try await pollFunction(request, interval, numAttempts)
      for try await _ in stream {
        XCTFail("No response should be received because an error occurs at first attempt")
      }
    } catch {
      // Expected to catch an error
      XCTAssertNotNil(error)
    }
  }

  func testPollingFunction_MaxAttemptsReached(
    pollFunction: @escaping (JobStatusRequest, TimeInterval, Int)
    async throws -> AsyncThrowingStream<JobStatusResponse<some JobResult>, Error>,
    requestBuilder: () -> JobStatusRequest
  ) async throws {
    let request = requestBuilder()
    let interval: TimeInterval = 1.0
    let numAttempts = 3

    MockHelper.shouldFail = false
    MockHelper.jobComplete = false

    let stream = try await pollFunction(request, interval, numAttempts)

    var responseCount = 0
    for try await response in stream {
      XCTAssertFalse(response.jobComplete, "Job should not be complete")
      responseCount += 1
    }
    XCTAssertEqual(responseCount, numAttempts, "Should receive exactly \(numAttempts) responses")
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
      signature: "")
    }

    try await testPollJobStatus_Success(
      pollFunction: mockService.pollSmartSelfieJobStatus,
      expectedResponse: expectedResponse,
      requestBuilder: requestBuilder)

    await testPollingFunction_ErrorDuringPolling(
      pollFunction: mockService.pollSmartSelfieJobStatus,
      requestBuilder: requestBuilder)

    try await testPollingFunction_MaxAttemptsReached(
      pollFunction: mockService.pollSmartSelfieJobStatus,
      requestBuilder: requestBuilder)
  }

  func testPollDocumentVerificationJobStatus() async throws {
    let expectedResponse = DocumentVerificationJobStatusResponse(jobComplete: true)
    let requestBuilder = { JobStatusRequest(
      userId: "",
      jobId: "",
      includeImageLinks: true,
      includeHistory: true,
      partnerId: "",
      timestamp: "",
      signature: "")
    }

    try await testPollJobStatus_Success(
      pollFunction: mockService.pollDocumentVerificationJobStatus,
      expectedResponse: expectedResponse,
      requestBuilder: requestBuilder)

    await testPollingFunction_ErrorDuringPolling(
      pollFunction: mockService.pollDocumentVerificationJobStatus,
      requestBuilder: requestBuilder)

    try await testPollingFunction_MaxAttemptsReached(
      pollFunction: mockService.pollDocumentVerificationJobStatus,
      requestBuilder: requestBuilder)
  }

  func testPollBiometricKycJobStatus() async throws {
    let expectedResponse = BiometricKycJobStatusResponse(jobComplete: true)
    let requestBuilder = { JobStatusRequest(
      userId: "",
      jobId: "",
      includeImageLinks: true,
      includeHistory: true,
      partnerId: "",
      timestamp: "",
      signature: "")
    }

    try await testPollJobStatus_Success(
      pollFunction: mockService.pollBiometricKycJobStatus,
      expectedResponse: expectedResponse,
      requestBuilder: requestBuilder)

    await testPollingFunction_ErrorDuringPolling(
      pollFunction: mockService.pollBiometricKycJobStatus,
      requestBuilder: requestBuilder)

    try await testPollingFunction_MaxAttemptsReached(
      pollFunction: mockService.pollBiometricKycJobStatus,
      requestBuilder: requestBuilder)
  }

  func testPollEnhancedDocumentVerificationJobStatus() async throws {
    let expectedResponse = EnhancedDocumentVerificationJobStatusResponse(jobComplete: true)
    let requestBuilder = { JobStatusRequest(
      userId: "",
      jobId: "",
      includeImageLinks: true,
      includeHistory: true,
      partnerId: "",
      timestamp: "",
      signature: "")
    }

    try await testPollJobStatus_Success(
      pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
      expectedResponse: expectedResponse,
      requestBuilder: requestBuilder)

    await testPollingFunction_ErrorDuringPolling(
      pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
      requestBuilder: requestBuilder)

    try await testPollingFunction_MaxAttemptsReached(
      pollFunction: mockService.pollEnhancedDocumentVerificationJobStatus,
      requestBuilder: requestBuilder)
  }
}
