import SmileID
import Combine

class CountryListViewModel: ObservableObject {
    @Published var validDocuments = [ValidDocument]()
    @Published var isLoading = false
    private var subscribers = Set<AnyCancellable>()

    func getValidDocuments() {
        isLoading = true
        let authRequest = AuthenticationRequest(
            jobType: .documentVerification,
            enrollment: false,
            jobId: nil,
            userId: UUID().uuidString
        )

        SmileID.api.authenticate(request: authRequest)
            .flatMap { authResponse in
                let productRequest = ProductsConfigRequest(
                    partnerId: SmileID.config.partnerId,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.getValidDocuments(request: productRequest)
            }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        print(error.localizedDescription)
                    default:
                        break
                    }
                },
                receiveValue: { self.validDocuments = $0.validDocuments }
            )
            .store(in: &subscribers)
    }
}
