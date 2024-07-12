import Foundation
import SmileID

@MainActor
class JobsViewModel: ObservableObject {
    @Published private(set) var jobs: [JobData] = []
    @Published var showConfirmation: Bool = false
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    let config: Config
    let dataStoreClient: DataStoreClient

    init(
        config: Config,
        dataStoreClient: DataStoreClient = DataStoreClient()
    ) {
        self.config = config
        self.dataStoreClient = dataStoreClient
    }

    func fetchJobs() {
        do {
            jobs = try dataStoreClient.fetchJobs(
                partnerId: config.partnerId,
                isProduction: !SmileID.useSandbox
            )
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
