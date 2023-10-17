import Combine
import Foundation
import SmileID

class DocumentSelectorViewModel: ObservableObject {
    private var subscriber: AnyCancellable?

    // UI Properties
    @Published @MainActor var idTypes: [ValidDocument] = []
    @Published @MainActor var errorMessage: String?

    init() {
        let authRequest = AuthenticationRequest(
            jobType: .documentVerification,
            enrollment: false,
            userId: generateUserId()
        )
        subscriber = SmileID.api.authenticate(request: authRequest)
            .flatMap { authResponse in
                let productRequest = ProductsConfigRequest(
                    partnerId: SmileID.config.partnerId,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.getValidDocuments(request: productRequest)
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                    default:
                        break
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.idTypes = response.validDocuments
                    }
                }
            )
    }


}
