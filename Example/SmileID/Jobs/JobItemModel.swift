import Foundation
import SmileID

class JobItemModel: ObservableObject {
    @Published private(set) var job: JobData
    @Published private(set) var task: Task<Bool, Error>?

    let dataStoreClient: DataStoreClient

    init(
        job: JobData,
        dataStoreClient: DataStoreClient = DataStoreClient()
    ) {
        self.job = job
        self.dataStoreClient = dataStoreClient
    }

    private func sendAuthenticationRequest() async throws -> AuthenticationResponse {
        let authRequest = AuthenticationRequest(jobType: job.jobType)
        return try await SmileID.api.authenticate(request: authRequest)
    }

    private func getJobStatus() async throws -> Bool {
        let authResponse = try await sendAuthenticationRequest()

        let request = JobStatusRequest(
            userId: job.userId,
            jobId: job.jobId,
            timestamp: authResponse.timestamp,
            signature: authResponse.signature
        )

        switch job.jobType {
        case .biometricKyc:
            let response = try await SmileID.api.pollBiometricKycJobStatus(
                request: request,
                interval: 1,
                numAttempts: 30
            )
            return response.jobComplete
        case .smartSelfieAuthentication, .smartSelfieEnrollment:
            let response = try await SmileID.api.pollSmartSelfieJobStatus(
                request: request,
                interval: 1,
                numAttempts: 30
            )
            return response.jobComplete
        case .documentVerification:
            let response = try await SmileID.api.pollDocumentVerificationJobStatus(
                request: request,
                interval: 1,
                numAttempts: 30
            )
            return response.jobComplete
        case .enhancedDocumentVerification:
            let response = try await SmileID.api.pollEnhancedDocumentVerificationJobStatus(
                request: request,
                interval: 1,
                numAttempts: 30
            )
            return response.jobComplete
        default:
            return false
        }
    }

    @MainActor
    func updateJobStatus() async throws {
        guard !job.jobComplete, task == nil else { return }
        task = Task {
            return try await getJobStatus()
        }
        guard let task = self.task else { return }
        let status = try await task.value
        // TODO: - Update all the job details, cause at this state the job information is complete.
        if let updatedJob = try dataStoreClient.updateJob(data: job, status: status) {
            self.job = updatedJob
        }
    }
    
    func cancelTask() {
        self.task?.cancel()
        self.task = nil
    }
}
