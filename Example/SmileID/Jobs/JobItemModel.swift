import Foundation
import SmileID

class JobItemModel: ObservableObject {
  @Published private(set) var job: JobData
  @Published private(set) var task: Task<JobData, Error>?
  @Published private(set) var isLoading: Bool = false

  let dataStoreClient: DataStoreClient

  init(
    job: JobData,
    dataStoreClient: DataStoreClient = DataStoreClient()
  ) {
    self.job = job
    self.dataStoreClient = dataStoreClient
  }

  private func sendAuthenticationRequest() async throws -> AuthenticationResponse {
    let authRequest = AuthenticationRequest(
      jobType: job.jobType,
      jobId: job.jobId,
      userId: job.userId)
    return try await SmileID.api.authenticate(request: authRequest)
  }

  private func getJobStatus() async throws -> JobData {
    let authResponse = try await sendAuthenticationRequest()

    let request = JobStatusRequest(
      userId: job.userId,
      jobId: job.jobId,
      timestamp: authResponse.timestamp,
      signature: authResponse.signature)
    let pollStream = SmileID.api.pollJobStatus(
      request: request,
      interval: 1,
      numAttempts: 30)
    var response: JobStatusResponse<JobResult>?

    for try await res in pollStream {
      response = res
    }

    return JobData(
      jobType: job.jobType,
      timestamp: job.timestamp,
      userId: job.userId,
      jobId: job.jobId,
      partnerId: job.partnerId,
      jobComplete: response?.jobComplete ?? false,
      jobSuccess: response?.jobSuccess ?? false,
      code: response?.code,
      resultCode: response?.result?.resultCode,
      smileJobId: response?.result?.smileJobId,
      resultText: response?.result?.resultText,
      selfieImageUrl: response?.imageLinks?.selfieImageUrl)
  }

  @MainActor
  func updateJobStatus() async throws {
    guard !job.jobComplete, task == nil else { return }
    isLoading = true
    defer { isLoading = false }
    task = Task {
      try await getJobStatus()
    }
    guard let task else { return }
    let jobStatusResponse = try await task.value
    if let updatedJob = try dataStoreClient.updateJob(data: jobStatusResponse) {
      job = updatedJob
    }
  }

  func cancelTask() {
    isLoading = false
    task?.cancel()
    task = nil
  }
}
