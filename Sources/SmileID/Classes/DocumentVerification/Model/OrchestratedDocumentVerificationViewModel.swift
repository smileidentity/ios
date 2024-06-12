import Combine
import SwiftUI

enum DocumentCaptureFlow: Equatable {
    case frontDocumentCapture
    case backDocumentCapture
    case selfieCapture
    case processing(ProcessingState)
}

internal class IOrchestratedDocumentVerificationViewModel<T, U: JobResult>: ObservableObject {
    // Input properties
    internal let userId: String
    internal let jobId: String
    internal let allowNewEnroll: Bool
    internal let countryCode: String
    internal let documentType: String?
    internal let captureBothSides: Bool
    internal let jobType: JobType
    internal let extraPartnerParams: [String: String]

    // Other properties
    internal var documentFrontFile: Data?
    internal var documentBackFile: Data?
    internal var selfieFile: URL?
    internal var livenessFiles: [URL]?
    internal var savedFiles: DocumentCaptureResultStore?
    internal var stepToRetry: DocumentCaptureFlow?
    internal var didSubmitJob: Bool = false
    internal var error: Error?

    // UI properties
    @Published var acknowledgedInstructions = false
    @Published var errorMessage: String?
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    internal init(
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        selfieFile: URL?,
        jobType: JobType,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.selfieFile = selfieFile
        self.jobType = jobType
        self.extraPartnerParams = extraPartnerParams
    }

    func onFrontDocumentImageConfirmed(data: Data) {
        documentFrontFile = data
        if captureBothSides {
            DispatchQueue.main.async {
                self.step = .backDocumentCapture
            }
        } else {
            DispatchQueue.main.async {
                self.step = .selfieCapture
            }
        }
    }

    func onBackDocumentImageConfirmed(data: Data) {
        documentBackFile = data
        DispatchQueue.main.async {
            self.step = .selfieCapture
        }
    }

    func acknowledgeInstructions() {
        acknowledgedInstructions = true
    }

    func onError(error: Error) {
        self.error = error
        stepToRetry = step
        DispatchQueue.main.async {
            self.step = .processing(.error)
        }
    }

    func onDocumentBackSkip() {
        if selfieFile == nil {
            DispatchQueue.main.async {
                self.step = .selfieCapture
            }
        } else {
            submitJob()
        }
    }

    func onFinished(delegate _: T) {
        fatalError("Must override onFinished")
    }

    func submitJob() {
        guard let documentFrontFile else {
            // Set step to .frontDocumentCapture so that the Retry button goes back to this step
            step = .frontDocumentCapture
            onError(error: SmileIDError.unknown("Error getting document front file"))
            return
        }
        guard let selfieFile else {
            // Set step to .selfieCapture so that the Retry button goes back to this step
            step = .selfieCapture
            onError(error: SmileIDError.unknown("Error getting selfie file"))
            return
        }
        DispatchQueue.main.async {
            self.step = .processing(.inProgress)
        }
        Task {
            let zip: Data
            do {
                var allFiles = [URL]()
                let frontDocumentUrl = try LocalStorage.createDocumentFile(
                    jobId: jobId,
                    fileType: FileType.documentFront,
                    document: documentFrontFile
                )
                allFiles.append(contentsOf: [selfieFile, frontDocumentUrl])
                var backDocumentUrl: URL?
                if let documentBackFile {
                    let url = try LocalStorage.createDocumentFile(
                        jobId: jobId,
                        fileType: FileType.documentBack,
                        document: documentBackFile
                    )
                    backDocumentUrl = url
                    allFiles.append(url)
                }
                if let livenessFiles {
                    allFiles.append(contentsOf: livenessFiles)
                }
                let info = try LocalStorage.createInfoJsonFile(
                    jobId: jobId,
                    idInfo: IdInfo(country: countryCode),
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles
                )
                allFiles.append(info)
                let zipUrl = try LocalStorage.zipFiles(at: allFiles)
                zip = try Data(contentsOf: zipUrl)
                self.savedFiles = DocumentCaptureResultStore(
                    allFiles: allFiles,
                    documentFront: frontDocumentUrl,
                    documentBack: backDocumentUrl,
                    selfie: selfieFile,
                    livenessImages: livenessFiles ?? []
                )
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: false,
                    jobId: jobId,
                    userId: userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: jobId,
                        userId: userId,
                        jobType: jobType,
                        enrollment: false,
                        allowNewEnroll: allowNewEnroll,
                        partnerParams: extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: self.extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll), // TODO: - Fix when Michael changes this to boolean
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse = try await SmileID.api.prepUpload(request: prepUploadRequest)
                _ = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                )
                didSubmitJob = true
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                    self.selfieFile = try LocalStorage.getFileByType(
                        jobId: jobId,
                        fileType: FileType.selfie,
                        submitted: true
                    ) ?? selfieFile
                    self.livenessFiles = try LocalStorage.getFilesByType(
                        jobId: jobId,
                        fileType: FileType.liveness,
                        submitted: true
                    ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.onError(error: error)
                    return
                }
                DispatchQueue.main.async { self.step = .processing(.success) }
            } catch let error as SmileIDError {
                do {
                    let didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )
                    if didMove {
                        self.selfieFile = try LocalStorage.getFileByType(
                            jobId: jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        ) ?? selfieFile
                        self.livenessFiles = try LocalStorage.getFilesByType(
                            jobId: jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.onError(error: error)
                    return
                }
                if SmileID.allowOfflineMode, LocalStorage.isNetworkFailure(error: error) {
                    didSubmitJob = true
                    DispatchQueue.main.async {
                        self.errorMessage = "Offline.Message"
                        self.step = .processing(.success)
                    }
                } else {
                    didSubmitJob = false
                    print("Error submitting job: \(error)")
                    self.onError(error: error)
                }
            } catch {
                didSubmitJob = false
                print("Error submitting job: \(error)")
                self.onError(error: error)
            }
        }
    }

    /// If stepToRetry is ProcessingScreen, we're retrying a network issue, so we need to kick off
    /// the resubmission manually. Otherwise, we're retrying a capture error, so we just need to
    /// reset the UI state
    func onRetry() {
        let step = stepToRetry
        stepToRetry = nil
        if let stepToRetry = step {
            DispatchQueue.main.async {
                self.step = stepToRetry
            }
            if case .processing = stepToRetry {
                submitJob()
            }
        }
    }
}

extension IOrchestratedDocumentVerificationViewModel: SmartSelfieResultDelegate {
    func didSucceed(selfieImage: URL, livenessImages: [URL], apiResponse _: SmartSelfieResponse?) {
        selfieFile = selfieImage
        livenessFiles = livenessImages
        submitJob()
    }

    func didError(error: Error) {
        onError(error: SmileIDError.unknown("Error capturing selfie"))
    }
}

// swiftlint:disable opening_brace
internal class OrchestratedDocumentVerificationViewModel:
    IOrchestratedDocumentVerificationViewModel<DocumentVerificationResultDelegate, DocumentVerificationJobResult>
{
    override func onFinished(delegate: DocumentVerificationResultDelegate) {
        if let savedFiles {
            delegate.didSucceed(
                selfie: savedFiles.selfie,
                documentFrontImage: savedFiles.documentFront,
                documentBackImage: savedFiles.documentBack,
                didSubmitDocumentVerificationJob: didSubmitJob
            )
        } else if let error {
            // We check error as the 2nd case because as long as jobStatusResponse is not nil, it
            // was a success
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}

// swiftlint:disable opening_brace
internal class OrchestratedEnhancedDocumentVerificationViewModel:
    // swiftlint:disable line_length
    IOrchestratedDocumentVerificationViewModel<EnhancedDocumentVerificationResultDelegate, EnhancedDocumentVerificationJobResult>
{
    override func onFinished(delegate: EnhancedDocumentVerificationResultDelegate) {
        if let savedFiles {
            delegate.didSucceed(
                selfie: savedFiles.selfie,
                documentFrontImage: savedFiles.documentFront,
                documentBackImage: savedFiles.documentBack,
                didSubmitEnhancedDocVJob: didSubmitJob
            )
        } else if let error {
            // We check error as the 2nd case because as long as jobStatusResponse is not nil, it
            // was a success
            delegate.didError(error: error)
        } else {
            delegate.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}
