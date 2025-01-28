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
    }

    @MainActor
    func getServices() async throws {
        guard idTypes.isEmpty else { return }
        do {
            let authRequest = AuthenticationRequest(
                jobType: jobType,
                enrollment: false,
                userId: generateUserId()
            )
            let servicesResponse = try await SmileID.api.getServices()
            let authResponse = try await SmileID.api.authenticate(request: authRequest)
            let productRequest = ProductsConfigRequest(
                timestamp: authResponse.timestamp,
                signature: authResponse.signature
            )
            let validDocumentsResponse = try await SmileID.api.getValidDocuments(request: productRequest)
            let supportedDocuments = servicesResponse.hostedWeb.enhancedDocumentVerification
            if jobType == .enhancedDocumentVerification {
                self.idTypes = self.filteredForEnhancedDocumentVerification(
                    allDocuments: validDocumentsResponse.validDocuments,
                    supportedDocuments: supportedDocuments
                )
            } else {
                self.idTypes = validDocumentsResponse.validDocuments
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
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
