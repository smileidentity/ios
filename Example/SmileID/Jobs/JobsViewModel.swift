import Foundation
import SmileID

@MainActor
class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobData] = []
    
    let provider: JobsProvider
    
    init(provider: JobsProvider = JobsProvider()) {
        self.provider = provider
    }
    
    func fetchJobs() {
        jobs = provider.fetchJobs()
    }
    
    func addNewJob() {
        provider.saveJob(
            data: JobData(
                jobType: .biometricKyc,
                timestamp: "14/05/2024 16:12",
                userId: generateUserId(),
                jobId: generateJobId(),
                jobComplete: false,
                jobSuccess: false
            )
        )
    }
    
    func clearJobs() {
        provider.clearJobs()
    }
}
