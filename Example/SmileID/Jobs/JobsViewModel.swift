import Foundation
import SmileID

@MainActor
class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobData] = []
    @Published var showConfirmation: Bool = false
    
    let dataStoreClient: DataStoreClient
    
    init(dataStoreClient: DataStoreClient = DataStoreClient()) {
        self.dataStoreClient = dataStoreClient
    }
    
    func fetchJobs() {
        jobs = dataStoreClient.fetchJobs()
    }
    
    func clearButtonTapped() {
        showConfirmation = true
    }
    
    func clearJobs() {
        dataStoreClient.clearJobs()
        jobs.removeAll()
    }
}
