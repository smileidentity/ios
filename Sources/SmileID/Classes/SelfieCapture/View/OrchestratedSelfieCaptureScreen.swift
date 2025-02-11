import Foundation
import SwiftUI

public struct OrchestratedSelfieCaptureConfig {
    let userId: String
    let jobId: String
    let isEnroll: Bool
    let allowNewEnroll: Bool
    let allowAgentMode: Bool
    let showAttribution: Bool
    let showInstructions: Bool
    let extraPartnerParams: [String: String]
    let skipApiSubmission: Bool
    let useStrictMode: Bool

    /// - Parameters:
    ///   - userId: The user ID to associate with the SmartSelfie™ Enrollment. Most often, this will
    ///     correspond to a unique User ID within your own system. If not provided, a random user ID
    ///     will be generated.
    ///   - jobId: The job ID to associate with the SmartSelfie™ Enrollment. Most often, this will
    ///     correspond to a unique Job ID within your own system. If not provided, a random job ID
    ///     will be generated.
    ///   - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///   - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///     displayed allowing toggling between the back camera and front camera. If not allowed,
    ///     only the front camera will be used.
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions
    ///     screen
    ///   - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - useStrictMode: Whether to use enhanced selfie capture or regular selfie capture.
    public init(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        isEnroll: Bool = false,
        allowNewEnroll: Bool = false,
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        extraPartnerParams: [String : String] = [:],
        skipApiSubmission: Bool = false,
        useStrictMode: Bool = false
    ) {
        self.userId = userId
        self.jobId = jobId
        self.isEnroll = isEnroll
        self.allowNewEnroll = allowNewEnroll
        self.allowAgentMode = allowAgentMode
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.extraPartnerParams = extraPartnerParams
        self.skipApiSubmission = skipApiSubmission
        self.useStrictMode = useStrictMode
    }
}

class OrchestratedSelfieCaptureViewModel: ObservableObject {
    let captureConfig = SelfieCaptureConfig.defaultConfiguration
    let config: OrchestratedSelfieCaptureConfig
    let localMetadata: LocalMetadata
    
    // MARK: Private Properties
    private var selfieImage: URL?
    private var livenessImages: [URL] = []
    private var apiResponse: SmartSelfieResponse?
    private var error: Error?
    
    // MARK: UI Outputs
    @Published public private(set) var processingState: ProcessingState?
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published public var errorMessageRes: String?
    @Published public var errorMessage: String?
    
    init(
        config: OrchestratedSelfieCaptureConfig,
        localMetadata: LocalMetadata = LocalMetadata()
    ) {
        self.config = config
        self.localMetadata = localMetadata
    }
    
    public func submitJob() {
        localMetadata.addMetadata(
            Metadatum.ActiveLivenessType(livenessType: LivenessType.smile))
        if config.skipApiSubmission {
            DispatchQueue.main.async { self.processingState = .success }
            return
        }
        DispatchQueue.main.async { self.processingState = .inProgress }
        Task {
            do {
                guard let selfieImage, livenessImages.count == captureConfig.numLivenessImages
                else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                let jobType =
                config.isEnroll
                ? JobType.smartSelfieEnrollment
                : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: config.isEnroll,
                    jobId: config.jobId,
                    userId: config.userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: config.jobId,
                        userId: config.userId,
                        jobType: jobType,
                        enrollment: config.isEnroll,
                        allowNewEnroll: config.allowNewEnroll,
                        localMetadata: localMetadata,
                        partnerParams: config.extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(
                    request: authRequest)
                
                var smartSelfieLivenessImages = [MultipartBody]()
                var smartSelfieImage: MultipartBody?
                if let selfie = try? Data(contentsOf: selfieImage),
                   let media = MultipartBody(
                    withImage: selfie,
                    forKey: selfieImage.lastPathComponent,
                    forName: selfieImage.lastPathComponent
                   )
                {
                    smartSelfieImage = media
                }
                if !livenessImages.isEmpty {
                    let livenessImageInfos = livenessImages.compactMap { liveness -> MultipartBody? in
                        if let data = try? Data(contentsOf: liveness) {
                            return MultipartBody(
                                withImage: data,
                                forKey: liveness.lastPathComponent,
                                forName: liveness.lastPathComponent
                            )
                        }
                        return nil
                    }
                    
                    smartSelfieLivenessImages.append(
                        contentsOf: livenessImageInfos.compactMap { $0 })
                }
                guard let smartSelfieImage = smartSelfieImage,
                      smartSelfieLivenessImages.count == captureConfig.numLivenessImages
                else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                
                let response =
                if config.isEnroll {
                    try await SmileID.api.doSmartSelfieEnrollment(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        userId: config.userId,
                        partnerParams: config.extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil,
                        allowNewEnroll: config.allowNewEnroll,
                        failureReason: nil,
                        metadata: localMetadata.metadata
                    )
                } else {
                    try await SmileID.api.doSmartSelfieAuthentication(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        userId: config.userId,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        partnerParams: config.extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil,
                        failureReason: nil,
                        metadata: localMetadata.metadata
                    )
                }
                apiResponse = response
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.config.jobId)
                    self.selfieImage = try LocalStorage.getFileByType(
                        jobId: config.jobId,
                        fileType: FileType.selfie,
                        submitted: true
                    )
                    self.livenessImages =
                    try LocalStorage.getFilesByType(
                        jobId: config.jobId,
                        fileType: FileType.liveness,
                        submitted: true
                    ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                }
                DispatchQueue.main.async { self.processingState = .success }
            } catch let error as SmileIDError {
                do {
                    let didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.config.jobId,
                        error: error
                    )
                    if didMove {
                        self.selfieImage = try LocalStorage.getFileByType(
                            jobId: config.jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        )
                        self.livenessImages =
                        try LocalStorage.getFilesByType(
                            jobId: config.jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
                if SmileID.allowOfflineMode,
                   SmileIDError.isNetworkFailure(error: error)
                {
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.processingState = .success
                    }
                } else {
                    print("Error submitting job: \(error)")
                    let (errorMessageRes, errorMessage) = toErrorMessage(
                        error: error)
                    self.error = error
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                    DispatchQueue.main.async { self.processingState = .error }
                }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.processingState = .error }
            }
        }
    }
}

extension OrchestratedSelfieCaptureViewModel: SelfieCaptureDelegate {
    func didFinishWith(result: SelfieCaptureResult, error: (any Error)?) {
        // if there is no error, take the result and submit it
    }
}

/// Orchestrates the selfie capture flow - navigates between instructions, requesting permissions,
/// showing camera view, and displaying processing screen
public struct OrchestratedSelfieCaptureScreen: View {
    @Backport.StateObject private var viewModel: OrchestratedSelfieCaptureViewModel

    private let config: OrchestratedSelfieCaptureConfig
    private let onResult: SmartSelfieResultDelegate
    private let onDismiss: (() -> Void)?

    public init(
        config: OrchestratedSelfieCaptureConfig,
        onResult: SmartSelfieResultDelegate,
        onDismiss: (() -> Void)? = nil
    ) {
        self.config = config
        self.onResult = onResult
        self.onDismiss = onDismiss
        self._viewModel = Backport
            .StateObject(
                wrappedValue: OrchestratedSelfieCaptureViewModel(
                    config: config
                )
            )
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if config.showInstructions {
                    SmartSelfieInstructionsScreen(
                        showAttribution: config.showAttribution,
                        delegate: onResult,
                        didTapTakePhoto: {
                            // trigger show selfie capture.
                        }
                    )
                } else {
                    SelfieCaptureScreen(
                        isEnroll: config.isEnroll,
                        jobId: config.jobId,
                        delegate: viewModel
                    )
                }
            }
            .navigationBarItems(
                leading: Button {
                    onDismiss?()
                } label: {
                    Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                        .foregroundColor(SmileID.theme.accent)
                }
            )
        }
    }
}
