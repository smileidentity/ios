import Foundation
@preconcurrency import SmileID

enum EnhancedKycWithIdInputScreenStep {
  case loading(String)
  case idTypeSelection([CountryInfo])
  case consent(country: String, idType: String, requiredFields: [RequiredField])
  case idInput(country: String, idType: String, consentInformation: ConsentInformation?,
               requiredFields: [RequiredField])
  case processing(ProcessingState)
}

class EnhancedKycWithIdInputScreenViewModel: ObservableObject {
  let userId: String
  let jobId: String

  private var error: Error?
  private var enhancedKycResponse: EnhancedKycResponse?
  @Published @MainActor var step = EnhancedKycWithIdInputScreenStep.loading("Loading ID Types…")

  @Published @MainActor var idInfo = IdInfo(country: "")
  @Published @MainActor var consentInformation: ConsentInformation?

  init(userId: String, jobId: String) {
    self.userId = userId
    self.jobId = jobId
    loadIdTypes()
  }

  private func loadIdTypes() {
    let authRequest = AuthenticationRequest(
      jobType: .biometricKyc,
      enrollment: false,
      jobId: jobId,
      userId: userId)
    DispatchQueue.main.async { self.step = .loading("Loading ID Types…") }
    Task {
      do {
        let authResponse = try await SmileID.api.authenticate(request: authRequest)
        let productsConfigRequest = ProductsConfigRequest(
          timestamp: authResponse.timestamp,
          signature: authResponse.signature)
        let productsConfigResponse = try await SmileID.api.getProductsConfig(
          request: productsConfigRequest
        )
        let supportedCountries = productsConfigResponse.idSelection.enhancedKyc
        let servicesResponse = try await SmileID.api.getServices()
        let servicesCountryInfo = servicesResponse.hostedWeb.enhancedKyc
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
      idType: idType)
    DispatchQueue.main.async {
      self.step = .loading("Loading Consent…")
    }
    Task {
      do {
        let authResponse = try await SmileID.api.authenticate(request: authRequest)
        if authResponse.consentInfo?.consentRequired == true {
          DispatchQueue.main.async {
            self.step = .consent(
              country: country,
              idType: idType,
              requiredFields: requiredFields)
          }
        } else {
          onConsentGranted(
            country: country,
            idType: idType,
            consentInformation: nil,
            requiredFields: requiredFields)
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

  func onConsentGranted(country: String, idType: String,
                        consentInformation: ConsentInformation?,
                        requiredFields: [RequiredField]) {
    DispatchQueue.main.async {
      self.step = .idInput(
        country: country,
        idType: idType,
        consentInformation: consentInformation,
        requiredFields: requiredFields)
    }
  }

  func onIdFieldsEntered(idInfo: IdInfo, consentInformation: ConsentInformation?) {
    DispatchQueue.main.async {
      self.idInfo = idInfo
      self.consentInformation = consentInformation
      self.step = .processing(ProcessingState.inProgress)
    }
    doEnhancedKyc(idInfo: idInfo, consentInformation: consentInformation)
  }

  func doEnhancedKyc(idInfo: IdInfo, consentInformation: ConsentInformation?) {
    DispatchQueue.main.async { self.step = .loading("Loading...") }
    Task {
      do {
        let authRequest = AuthenticationRequest(
          jobType: .enhancedKyc,
          enrollment: false,
          jobId: jobId,
          userId: userId)
        let authResponse = try await SmileID.api.authenticate(request: authRequest)
        let enhancedKycRequest = EnhancedKycRequest(
          country: idInfo.country,
          idType: idInfo.idType!,
          idNumber: idInfo.idNumber!,
          consentInformation: consentInformation,
          firstName: idInfo.firstName,
          lastName: idInfo.lastName,
          dob: idInfo.dob,
          bankCode: idInfo.bankCode,
          partnerParams: authResponse.partnerParams,
          timestamp: authResponse.timestamp,
          signature: authResponse.signature)
        enhancedKycResponse = try await SmileID.api.doEnhancedKyc(
          request: enhancedKycRequest
        )
        DispatchQueue.main.async { self.step = .processing(.success) }
      } catch {
        self.error = error
        DispatchQueue.main.async { self.step = .processing(.error) }
      }
    }
  }

  @MainActor func onRetry() {
    doEnhancedKyc(idInfo: idInfo, consentInformation: consentInformation)
  }

  func onFinished(delegate: EnhancedKycResultDelegate) {
    if let error {
      delegate.didError(error: error)
    } else if let enhancedKycResponse {
      delegate.didSucceed(enhancedKycResponse: enhancedKycResponse)
    }
  }
}
