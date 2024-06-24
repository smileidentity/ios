import Foundation
import SmileID

@MainActor
class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobData] = []
    @Published var showConfirmation: Bool = false
    
    let provider: JobsProvider
    
    init(provider: JobsProvider = JobsProvider()) {
        self.provider = provider
    }
    
    func fetchJobs() {
        jobs = provider.fetchJobs()
    }
    
    func addNewJob() {
        let newJobData = JobData(
            jobType: .biometricKyc,
            timestamp: "14/05/2024 16:12",
            userId: generateUserId(),
            jobId: generateJobId(),
            jobComplete: false,
            jobSuccess: false
        )
        provider.saveJob(
            data: newJobData
        )
    }
    
    func clearButtonTapped() {
        showConfirmation = true
    }
    
    func clearJobs() {
        provider.clearJobs()
    }
}
