import Foundation
import SmileID

@MainActor
class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobData] = []
    @Published var showConfirmation: Bool = false
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    let dataStoreClient: DataStoreClient

    init(dataStoreClient: DataStoreClient = DataStoreClient()) {
        self.dataStoreClient = dataStoreClient
    }

    func fetchJobs() {
        do {
            jobs = try dataStoreClient.fetchJobs()
        } catch {
            toastMessage = error.localizedDescription
        }
    }

    func clearButtonTapped() {
        showConfirmation = true
    }

    func clearJobs() {
        do {
            try dataStoreClient.clearJobs()
            jobs.removeAll()
        } catch {
            toastMessage = error.localizedDescription
        }
    }
}
