import Combine
import Foundation
import SmileID

class DocumentSelectorViewModel: ObservableObject {
    // Input Properties
    let jobType: JobType

    // Other Properties
    private var subscriber: AnyCancellable?

    // UI Properties
    @Published @MainActor var idTypes: [ValidDocument] = []
    @Published @MainActor var errorMessage: String?

    init(jobType: JobType) {
        if jobType != .documentVerification && jobType != .enhancedDocumentVerification {
            fatalError("Only Document Verification jobs are supported")
        }
        self.jobType = jobType
        let authRequest = AuthenticationRequest(
            jobType: jobType,
            enrollment: false,
            userId: generateUserId()
        )
        let services = SmileID.api.getServices()
        subscriber = SmileID.api.authenticate(request: authRequest)
            .flatMap { authResponse in
                let productRequest = ProductsConfigRequest(
                    partnerId: SmileID.config.partnerId,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                return SmileID.api.getValidDocuments(request: productRequest)
            }
            .zip(services)
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
                receiveValue: { (validDocumentsResponse, servicesResponse) in
                    let supportedDocuments = servicesResponse.hostedWeb.enhancedDocumentVerification
                    DispatchQueue.main.async {
                        if jobType == .enhancedDocumentVerification {
                            self.idTypes = self.filteredForEnhancedDocumentVerification(
                                allDocuments: validDocumentsResponse.validDocuments,
                                supportedDocuments: supportedDocuments
                            )
                        } else {
                            self.idTypes = validDocumentsResponse.validDocuments
                        }
                    }
                }
            )
    }

    private func filteredForEnhancedDocumentVerification(
        allDocuments: [ValidDocument],
        supportedDocuments: [CountryInfo]
    ) -> [ValidDocument] {
        supportedDocuments.compactMap { country in
            let validDocumentForCountry = allDocuments.first {
                $0.country.code == country.countryCode
            }
            if let validDocumentForCountry = validDocumentForCountry {
                return ValidDocument(
                    country: Country(code: country.countryCode, continent: "", name: country.name),
                    idTypes: country.availableIdTypes.flatMap { idType in
                        validDocumentForCountry.idTypes.filter { $0.code == idType.idTypeKey }
                    }
                )
            } else {
                return nil
            }
        }
    }
}
