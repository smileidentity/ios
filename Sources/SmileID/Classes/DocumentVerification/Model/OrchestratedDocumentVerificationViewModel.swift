import Combine
import SwiftUI

enum DocumentCaptureFlow: Equatable {
    case frontDocumentCapture
    case backDocumentCapture
    case selfieCapture
    case processing(ProcessingState)
}

class IOrchestratedDocumentVerificationViewModel<T, U: JobResult,S:CaptureResult>: BaseSubmissionViewModel<S> {
    // Input properties
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let countryCode: String
    let documentType: String?
    let captureBothSides: Bool
    let skipApiSubmission: Bool
    let jobType: JobType
    let extraPartnerParams: [String: String]

    // Other properties
    var documentFrontFile: Data?
    var documentBackFile: Data?
    var selfieFile: URL?
    var livenessFiles: [URL]?
    var savedFiles: DocumentCaptureResultStore?
    var stepToRetry: DocumentCaptureFlow?
    var didSubmitJob: Bool = false
    var error: Error?
    var localMetadata: LocalMetadata

    // UI properties
    @Published var acknowledgedInstructions = false
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published var step = DocumentCaptureFlow.frontDocumentCapture

    init(
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        countryCode: String,
        documentType: String?,
        captureBothSides: Bool,
        skipApiSubmission: Bool,
        selfieFile: URL?,
        jobType: JobType,
        extraPartnerParams: [String: String] = [:],
        localMetadata: LocalMetadata
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.countryCode = countryCode
        self.documentType = documentType
        self.captureBothSides = captureBothSides
        self.skipApiSubmission = skipApiSubmission
        self.selfieFile = selfieFile
        self.jobType = jobType
        self.extraPartnerParams = extraPartnerParams
        self.localMetadata = localMetadata
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
        Task {
            do {
                guard let documentFrontFile else {
                    // Set step to .frontDocumentCapture so that the Retry button goes back to this step
                    step = .frontDocumentCapture
                    onError(error: SmileIDError.unknown("Error getting document front file"))
                    return
                }

                selfieFile = try LocalStorage.getFileByType(
                    jobId: jobId,
                    fileType: FileType.selfie
                )

                livenessFiles = try LocalStorage.getFilesByType(
                    jobId: jobId,
                    fileType: FileType.liveness
                )

                guard let selfieFile else {
                    // Set step to .selfieCapture so that the Retry button goes back to this step
                    step = .selfieCapture
                    onError(error: SmileIDError.unknown("Error getting selfie file"))
                    return
                }

                DispatchQueue.main.async {
                    self.step = .processing(.inProgress)
                }

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
    func didSucceed(
        selfieImage _: URL,
        livenessImages _: [URL],
        apiResponse _: SmartSelfieResponse?
    ) {
        submitJob()
    }

    func didError(error: Error) {
        onError(error: SmileIDError.unknown("Error capturing selfie"))
    }
}

// swiftlint:disable opening_brace
class OrchestratedDocumentVerificationViewModel:
    IOrchestratedDocumentVerificationViewModel<DocumentVerificationResultDelegate, DocumentVerificationJobResult,DocumentVerificationResult>
{
    override func onFinished(delegate: DocumentVerificationResultDelegate) {
        if let savedFiles,
           let selfiePath = getRelativePath(from: selfieFile),
           let documentFrontPath = getRelativePath(from: savedFiles.documentFront),
           let documentBackPath = getRelativePath(from: savedFiles.documentBack)
        {
            delegate.didSucceed(
                selfie: selfiePath,
                documentFrontImage: documentFrontPath,
                documentBackImage: documentBackPath,
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
class OrchestratedEnhancedDocumentVerificationViewModel:IOrchestratedDocumentVerificationViewModel<
EnhancedDocumentVerificationResultDelegate, EnhancedDocumentVerificationJobResult,EnhancedDocumentVerificationResult
    >
{
    override func onFinished(delegate: EnhancedDocumentVerificationResultDelegate) {
        if let savedFiles,
           let selfiePath = getRelativePath(from: selfieFile),
           let documentFrontPath = getRelativePath(from: savedFiles.documentFront),
           let documentBackPath = getRelativePath(from: savedFiles.documentBack)
        {
            delegate.didSucceed(
                selfie: selfiePath,
                documentFrontImage: documentFrontPath,
                documentBackImage: documentBackPath,
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
