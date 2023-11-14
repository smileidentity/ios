import Combine
import Foundation

internal enum BiometricKycStep {
    case loading(messageKey: String)
    case idTypeSelection([CountryInfo])
    case consent(country: String, idType: String, requiredFields: [RequiredField])
    case idInput(country: String, idType: String, requiredFields: [RequiredField])
    case selfie
    case processing(ProcessingState)
}

internal class OrchestratedBiometricKycViewModel: ObservableObject, SelfieImageCaptureDelegate {
    // MARK: - Input Properties
    private let userId: String
    private let jobId: String
    private var idInfo: IdInfo?

    // MARK: - Other Properties
    private var error: Error?
    private var selfieCaptureResultStore: SelfieCaptureResultStore?
    private var jobStatusResponse: BiometricKycJobStatusResponse?

    // MARK: - UI Properties
    @Published @MainActor private (set) var step: BiometricKycStep = .loading(
        messageKey: "BiometricKYC.Loading.IdTypes"
    )

    init(userId: String, jobId: String, idInfo: IdInfo?) {
        self.userId = userId
        self.jobId = jobId
        self.idInfo = idInfo
        if let idInfo = idInfo {
            guard let idType = idInfo.idType else {
                fatalError("You are expected to pass in the idType if you pass in idInfo")
            }
            // On this code path, we don't need to load services, ever, at all
            loadConsent(country: idInfo.country, idType: idType, requiredFields: [])
        } else {
            loadIdTypes()
        }
    }

    private func loadIdTypes() {
        let authRequest = AuthenticationRequest(
            jobType: .biometricKyc,
            enrollment: false,
            jobId: jobId,
            userId: userId
        )
        DispatchQueue.main.async {
            self.step = .loading(messageKey: "BiometricKYC.Loading.IdTypes")
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
                self.error = error
                DispatchQueue.main.async { self.step = .processing(.error) }
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
            self.step = .loading(messageKey: "BiometricKYC.Loading.Consent")
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
                self.error = error
                DispatchQueue.main.async { self.step = .processing(.error) }
            }
        }
    }

    func onIdTypeSelected(country: String, idType: String, requiredFields: [RequiredField]) {
        loadConsent(country: country, idType: idType, requiredFields: requiredFields)
    }

    func onConsentGranted(country: String, idType: String, requiredFields: [RequiredField]) {
        // If idInfo is already set, it was passed in, so we skip straight to selfie capture -- the
        // partner is required to pass in all required inputs
        if idInfo != nil {
            DispatchQueue.main.async { self.step = .selfie }
        } else {
            DispatchQueue.main.async {
                self.step = .idInput(
                    country: country,
                    idType: idType,
                    requiredFields: requiredFields
                )
            }
        }
    }

    func onIdFieldsEntered(idInfo: IdInfo) {
        self.idInfo = idInfo
        DispatchQueue.main.async { self.step = .selfie }
    }

    func didCapture(selfie: Data, livenessImages: [Data]) {
        selfieCaptureResultStore = try? LocalStorage.saveSelfieImages(
            selfieImage: selfie,
            livenessImages: livenessImages
        )
        if let selfieCaptureResultStore = selfieCaptureResultStore {
            submitJob(selfieCaptureResultStore: selfieCaptureResultStore)
        } else {
            error = SmileIDError.unknown("Failed to save selfie capture result")
            DispatchQueue.main.async { self.step = .processing(.error) }
        }
    }

    func onRetry() {
        if idInfo == nil {
            loadIdTypes()
        } else if selfieCaptureResultStore == nil {
            DispatchQueue.main.async { self.step = .selfie }
        } else {
            submitJob(selfieCaptureResultStore: selfieCaptureResultStore!)
        }
    }

    func onFinished(delegate: BiometricKycResultDelegate) {
        if let jobStatusResponse = jobStatusResponse,
           let selfieCaptureResultStore = selfieCaptureResultStore {
            delegate.didSucceed(
                selfieImage: selfieCaptureResultStore.selfie,
                livenessImages: selfieCaptureResultStore.livenessImages,
                jobStatusResponse: jobStatusResponse
            )
        } else if let error = error {
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("onFinish with no result or error"))
        }
    }

    func submitJob(selfieCaptureResultStore: SelfieCaptureResultStore) {
        DispatchQueue.main.async { self.step = .processing(.inProgress) }
        guard let idInfo = idInfo else {
            print("idInfo is nil")
            error = SmileIDError.unknown("idInfo is nil")
            DispatchQueue.main.async { self.step = .processing(.error) }
            return
        }
        Task {
            do {
                let livenessImages = selfieCaptureResultStore.livenessImages
                let selfieImage = selfieCaptureResultStore.selfie
                let infoJson = try LocalStorage.createInfoJson(
                    selfie: selfieImage,
                    livenessImages: livenessImages,
                    idInfo: idInfo
                )
                let zipUrl = try LocalStorage.zipFiles(
                    at: livenessImages + [selfieImage] + [infoJson]
                )
                let zip = try Data(contentsOf: zipUrl)
                let authRequest = AuthenticationRequest(
                    jobType: .biometricKyc,
                    enrollment: false,
                    jobId: jobId,
                    userId: userId
                )
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse = try await SmileID.api.prepUpload(
                    request: prepUploadRequest
                ).async()
                let _ = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                ).async()
                let jobStatusRequest = JobStatusRequest(
                    userId: userId,
                    jobId: jobId,
                    includeImageLinks: false,
                    includeHistory: false,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                jobStatusResponse = try await SmileID.api.getJobStatus(
                    request: jobStatusRequest
                ).async()
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.step = .processing(.error) }
            }
        }
    }
}
