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
            userId: job.userId
        )
        return try await SmileID.api.authenticate(request: authRequest)
    }

    private func getJobStatus() async throws -> JobData {
        let authResponse = try await sendAuthenticationRequest()

        let request = JobStatusRequest(
            userId: job.userId,
            jobId: job.jobId,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )

        let response = try await SmileID.api.pollJobStatus(
            request: request,
            interval: 1,
            numAttempts: 30
        )

        return JobData(
            jobType: job.jobType,
            timestamp: job.timestamp,
            userId: job.userId,
            jobId: job.jobId,
            partnerId: job.partnerId,
            jobComplete: response.jobComplete,
            jobSuccess: response.jobSuccess,
            code: response.code,
            resultCode: response.result?.resultCode,
            smileJobId: response.result?.smileJobId,
            resultText: response.result?.resultText,
            selfieImageUrl: response.imageLinks?.selfieImageUrl
        )
    }

    @MainActor
    func updateJobStatus() async throws {
        guard !job.jobComplete, task == nil else { return }
        isLoading = true
        defer { isLoading = false }
        task = Task {
            return try await getJobStatus()
        }
        guard let task = self.task else { return }
        let jobStatusResponse = try await task.value
        if let updatedJob = try dataStoreClient.updateJob(data: jobStatusResponse) {
            self.job = updatedJob
        }
    }

    func cancelTask() {
        self.task?.cancel()
        self.task = nil
    }
}
