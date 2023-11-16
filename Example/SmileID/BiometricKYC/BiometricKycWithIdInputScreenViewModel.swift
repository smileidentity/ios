import Foundation
import SmileID

enum BiometricKycWithIdInputScreenStep {
    case loading(String)
    case idTypeSelection([CountryInfo])
    case consent(country: String, idType: String, requiredFields: [RequiredField])
    case idInput(country: String, idType: String, requiredFields: [RequiredField])
    case sdk(IdInfo)
}

class BiometricKycWithIdInputScreenViewModel: ObservableObject {
    private let userId = generateUserId()
    private let jobId = generateJobId()

    @Published @MainActor var step = BiometricKycWithIdInputScreenStep.loading("Loading ID Types…")

    init() {
        loadIdTypes()
    }

    private func loadIdTypes() {
        let authRequest = AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: jobId,
            userId: userId
        )
        DispatchQueue.main.async {
            self.step = .loading("Loading ID Types…")
        }
        Task {
            do {
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                let productsConfigRequest = ProductsConfigRequest(
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let productsConfigResponse = try await SmileID.api.getProductsConfig(
                    request: productsConfigRequest
                ).async()
                let supportedCountries = productsConfigResponse.idSelection.biometricKyc
                let servicesResponse = try await SmileID.api.getServices().async()
                let servicesCountryInfo = servicesResponse.hostedWeb.biometricKyc
                // sort by country name
                let countryList = servicesCountryInfo
                    .filter { supportedCountries.keys.contains($0.countryCode) }
                    .sorted { $0.name < $1.name }
                DispatchQueue.main.async { self.step = .idTypeSelection(countryList) }
            } catch {
                print("Error loading id types: \(error)")
                DispatchQueue.main.async {
                    self.step = .loading("Error loading ID Types. Please try again.")
                }
            }
        }
    }

    private func loadConsent(
        country: String,
        idType: String,
        requiredFields: [RequiredField]
    ) {
        let authRequest = AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: jobId,
            userId: userId,
            country: country,
            idType: idType
        )
        DispatchQueue.main.async {
            self.step = .loading("Loading Consent…")
        }
        Task {
            do {
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                if authResponse.consentInfo?.consentRequired == true {
                    DispatchQueue.main.async {
                        self.step = .consent(
                            country: country,
                            idType: idType,
                            requiredFields: requiredFields
                        )
                    }
                } else {
                    // We don't need consent. Proceed forward as if consent has already been granted
                    onConsentGranted(
                        country: country,
                        idType: idType,
                        requiredFields: requiredFields
                    )
                }
            } catch {
                print("Error loading consent: \(error)")
                DispatchQueue.main.async {
                    self.step = .loading("Error loading consent. Please try again.")
                }
            }
        }
    }

    func onIdTypeSelected(country: String, idType: String, requiredFields: [RequiredField]) {
        loadConsent(country: country, idType: idType, requiredFields: requiredFields)
    }

    func onConsentGranted(country: String, idType: String, requiredFields: [RequiredField]) {
        DispatchQueue.main.async {
            self.step = .idInput(
                country: country,
                idType: idType,
                requiredFields: requiredFields
            )
        }
    }

    func onIdFieldsEntered(idInfo: IdInfo) {
        DispatchQueue.main.async { self.step = .sdk(idInfo) }
    }
}
