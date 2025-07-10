import FingerprintJS
import Foundation
import SwiftUI
import UIKit

public class SmileID {
    /// The default value for `timeoutIntervalForRequest` for URLSession default configuration.
    public static let defaultRequestTimeout: TimeInterval = 60
    public static let version = "11.0.2"
    @Injected var injectedApi: SmileIDServiceable
    public static var configuration: Config { config }

    public static var api: SmileIDServiceable { SmileID.instance.injectedApi }

    static let instance: SmileID = {
        let container = DependencyContainer.shared
        container.register(SmileIDServiceable.self) { SmileIDService() }
        container.register(RestServiceClient.self) {
            URLSessionRestServiceClient(
                session: SmileID.urlSession,
                requestTimeout: SmileID.requestTimeout
            )
        }
        container.register(ServiceHeaderProvider.self) { DefaultServiceHeaderProvider() }
        container.register(Metadata.self) { Metadata.shared }
        let instance = SmileID()
        return instance
    }()

    /// A private static constant that initializes a `URLSession` with a default configuration.
    /// This `URLSession` is used for creating `URLSessionDataTask`s in the networking layer.
    /// The session configuration sets the timeout interval for requests to the value specified by
    /// `SmileID.requestTimeout`.
    ///
    /// - Returns: A `URLSession` instance with the specified configuration.
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = SmileID.requestTimeout
        let session = URLSession(configuration: configuration)
        return session
    }()

    private init() {}

    public private(set) static var config: Config!
    public private(set) static var useSandbox = false
    public private(set) static var allowOfflineMode = false
    public private(set) static var callbackUrl: String = ""

    private(set) static var deviceId: String = ""
    private(set) static var sdkLaunchCount: Int = 0
    private(set) static var wrapperSdkName: WrapperSdkName? = nil
    private(set) static var wrapperSdkVersion: String? = nil

    static var apiKey: String?
    public private(set) static var theme: SmileIdTheme = DefaultTheme()
    private(set) static var localizableStrings: SmileIDLocalizableStrings?
    /// The timeout interval for requests. This value is initialized to the `defaultRequestTimeout`.
    private(set) static var requestTimeout: TimeInterval = SmileID.defaultRequestTimeout

    /// This method initializes SmileID. Invoke this method once in your application lifecycle
    /// before calling any other SmileID methods.
    /// - Parameters:
    ///   - config: The smile config file. If no value is supplied, we check the app's main bundle
    ///    for a `smile_config.json` file.
    ///   - useSandbox: A boolean to enable the sandbox environment or not
    ///   - requestTimeout: The timeout interval for all requests.
    ///   An interval greater than `defaultRequestTimeout` is recommended.
    public class func initialize(
        config: Config = getConfig(),
        useSandbox: Bool = false,
        requestTimeout: TimeInterval = SmileID.defaultRequestTimeout
    ) {
        initialize(
            apiKey: nil,
            config: config,
            useSandbox: useSandbox,
            requestTimeout: requestTimeout
        )
    }

    /// This method initializes SmileID. Invoke this method once in your application lifecylce
    /// before calling any other SmileID methods.
    /// - Parameters:
    ///   - apiKey: The api key displayed on your partner portal
    ///   - config: The smile config file. If no value is supplied, we check the app's main bundle
    ///    for a `smile_config.json` file.
    ///   - useSandbox: A boolean to enable the sandbox environment or not
    ///   - requestTimeout: The timeout interval for all requests.
    ///   An interval greater than `defaultRequestTimeout` is recommended.
    public class func initialize(
        apiKey: String? = nil,
        config: Config = getConfig(),
        useSandbox: Bool = false,
        requestTimeout: TimeInterval = SmileID.defaultRequestTimeout
    ) {
        self.config = config
        self.useSandbox = useSandbox
        self.apiKey = apiKey
        self.requestTimeout = requestTimeout

        SmileIDResourcesHelper.registerFonts()

        // Increment and track SDK launch count
        trackSdkLaunchCount()
        
        let fingerprinter = FingerprinterFactory.getInstance()
        Task {
            /// The fingerprint isn't currently as stable as the Device Identifier, because the
            /// values might change between OS updates or when the user changes settings
            /// used to compute the previous value.
            /// https://github.com/fingerprintjs/fingerprintjs-ios
            if let fingerprint = await fingerprinter.getDeviceId() {
                deviceId = fingerprint
            }
        }
    }

    /// Tracks the SDK launch count by incrementing a counter stored in UserDefaults
    private class func trackSdkLaunchCount() {
        let defaults = UserDefaults.standard
        let key = "SmileID.SDKLaunchCount"
        let currentCount = defaults.integer(forKey: key)
        let newCount = currentCount + 1
        defaults.set(newCount, forKey: key)

        sdkLaunchCount = newCount
    }

    /// Sets the state of offline mode for the SDK.
    /// This function enables or disables the SDK's ability to operate in offline mode,
    /// where it can continue functioning without an active internet connection. When offline mode
    /// is enabled (allowOfflineMode = true), the SDK will attempt to use capture and cache
    /// images in local file storage and will not attempt to submit the job. Conversely, when offline
    /// mode is disabled (allowOfflineMode = false), the application will require an active internet
    /// connection for all operations that involve data fetching or submission.
    ///
    /// - Parameter allowOfflineMode: A Boolean value indicating whether offline mode should
    /// be enabled (true) or disabled (false).
    public class func setAllowOfflineMode(allowOfflineMode: Bool) {
        SmileID.allowOfflineMode = allowOfflineMode
    }

    /// Retrieves a list of unsubmitted job IDs.
    public class func getUnsubmittedJobs() -> [String] {
        LocalStorage.getUnsubmittedJobs()
    }

    /// Retrieves a list of submitted job IDs.
    public class func getSubmittedJobs() -> [String] {
        LocalStorage.getSubmittedJobs()
    }

    /// Initiates the cleanup process for a single job by its ID.
    /// This is a convenience method that wraps the cleanup process, allowing for a single job ID
    /// to be specified for cleanup.
    ///
    /// - Parameter jobId: the job IDs to clean up.
    public class func cleanup(jobId: String) throws {
        try cleanup(jobIds: [jobId])
    }

    ///  Initiates the cleanup process for multiple jobs by their IDs.
    ///  If no IDs are provided, a default cleanup process is initiated that may target
    ///  specific jobs based on the implementation in com.smileidentity.util.cleanup.
    ///
    /// - Parameter jobIds: An optional list of job IDs to clean up. If null, the method defaults
    ///  to  a predefined cleanup process.
    public class func cleanup(jobIds: [String]? = nil) throws {
        if let jobIds {
            try LocalStorage.delete(at: jobIds)
        } else {
            try LocalStorage.deleteAll()
        }
    }

    /// Submits a previously captured job to SmileID for processing.
    ///
    /// - Parameters:
    ///   - jobId: The unique identifier for the job to be submitted.
    public class func submitJob(
        jobId: String,
        deleteFilesOnSuccess: Bool = true
    ) throws {
        let jobIds = LocalStorage.getUnsubmittedJobs()
        if !jobIds.contains(jobId) {
            throw SmileIDError.invalidJobId
        }
        guard let authRequestFile = try? LocalStorage.fetchAuthenticationRequestFile(jobId: jobId)
        else {
            throw SmileIDError.fileNotFound("Authentication Request file is missing")
        }
        guard let prepUploadFile = try? LocalStorage.fetchPrepUploadFile(jobId: jobId) else {
            throw SmileIDError.fileNotFound("Prep Upload file is missing")
        }
        Task {
            do {
                let authRequest = AuthenticationRequest(
                    jobType: authRequestFile.jobType,
                    enrollment: authRequestFile.enrollment,
                    jobId: authRequestFile.jobId,
                    userId: authRequestFile.userId
                )
                let authResponse = try await SmileID.api.authenticate(request: authRequest)
                var prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(
                        extras: prepUploadFile.partnerParams.extras
                    ),
                    allowNewEnroll: prepUploadFile.allowNewEnroll,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse: PrepUploadResponse
                do {
                    prepUploadResponse = try await SmileID.api.prepUpload(
                        request: prepUploadRequest
                    )
                } catch let error as SmileIDError {
                    switch error {
                    case .api("2215", _):
                        prepUploadRequest.retry = true
                        prepUploadResponse = try await SmileID.api.prepUpload(
                            request: prepUploadRequest
                        )
                    default:
                        throw error
                    }
                }
                let allFiles: [URL]
                do {
                    let livenessFiles =
                    try LocalStorage.getFilesByType(jobId: jobId, fileType: .liveness) ?? []
                    let additionalFiles = try [
                        LocalStorage.getFileByType(jobId: jobId, fileType: .selfie),
                        LocalStorage.getFileByType(jobId: jobId, fileType: .documentFront),
                        LocalStorage.getFileByType(jobId: jobId, fileType: .documentBack),
                        LocalStorage.getInfoJsonFile(jobId: jobId)
                    ].compactMap { $0 }
                    allFiles = livenessFiles + additionalFiles
                } catch {
                    throw error
                }
                let zipData = try LocalStorage.zipFiles(urls: allFiles)
                _ = try await SmileID.api.upload(
                    zip: zipData,
                    to: prepUploadResponse.uploadUrl
                )
                if deleteFilesOnSuccess {
                    do {
                        try LocalStorage.delete(at: [jobId])
                    } catch {
                        print("Error deleting submitted job: \(error)")
                    }
                } else {
                    do {
                        try LocalStorage.moveToSubmittedJobs(jobId: jobId)
                    } catch {
                        print("Error moving job to submitted directory: \(error)")
                    }
                }
                print("Upload finished")
            } catch {
                print("Error submitting job: \(error)")
                throw error
            }
        }
    }

    /// Set the callback URL for all submitted jobs. If no value is set, the default callback URL
    /// from the partner portal will be used.
    /// - Parameter url: A valid URL pointing to your server
    public class func setCallbackUrl(url: URL?) {
        SmileID.callbackUrl = url?.absoluteString ?? ""
    }

    /// Apply theme
    /// - Parameter theme: A `SmileIdTheme` used to override the colors and fonts used within the
    /// SDK. If no value is set, the default theme will be used.
    public class func apply(_ theme: SmileIdTheme) {
        self.theme = theme
    }

    /// Apply localizable strings
    /// - Parameter localizableStrings: A `SmileIDLocalizableStrings`  used to override all copy
    /// used within the SDK. if no value is set, the default copy will be used.
    public class func apply(_ localizableStrings: SmileIDLocalizableStrings) {
        self.localizableStrings = localizableStrings
    }

    /// Sets the name and version of a x-platform sdk that wraps the native sdk.
    /// This is an internal function and should not be used by partner developers.
    /// - Parameters:
    ///   - name: The name of the x-platform sdk that wraps the native sdk.
    ///   - version: The version of the x-platform sdk that wraps the native sdk.
    public class func setWrapperInfo(name: WrapperSdkName, version: String) {
        wrapperSdkName = name
        wrapperSdkVersion = version
    }

    /// Load the Config object from a json file
    /// - Parameter resourceName: The name of the json file. Defaults to `smile_config`
    /// - Returns: A `Config` object
    public static func getConfig(from resourceName: String = "smile_config") -> Config {
        let decoder = JSONDecoder()
        let configUrl = Bundle.main.url(forResource: resourceName, withExtension: "json")!
        // swiftlint:disable force_try
        return try! decoder.decode(Config.self, from: Data(contentsOf: configUrl))
        // swiftlint:enable force_try
    }

    /// Perform a SmartSelfie™ Enrollment
    ///
    /// Docs: https://docs.usesmileid.com/products/for-individuals-kyc/biometric-authentication
    ///
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
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Enrollment is complete.
    @ViewBuilder public class func smartSelfieEnrollmentScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowNewEnroll: Bool = false,
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        useStrictMode _: Bool = false,
        skipApiSubmission: Bool = false,
        extraPartnerParams: [String: String] = [:],
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedSelfieCaptureScreen(
            userId: userId,
            jobId: jobId,
            isEnroll: true,
            allowNewEnroll: allowNewEnroll,
            allowAgentMode: allowAgentMode,
            showAttribution: showAttribution,
            showInstructions: showInstructions,
            extraPartnerParams: extraPartnerParams,
            skipApiSubmission: skipApiSubmission,
            onResult: delegate
        )
    }

    /// Perform a SmartSelfie™ Enrollment
    ///
    /// Docs: https://docs.usesmileid.com/products/for-individuals-kyc/biometric-authentication
    ///
    /// - Parameters:
    ///   - userId: The user ID to associate with the SmartSelfie™ Enrollment. Most often, this will
    ///     correspond to a unique User ID within your own system. If not provided, a random user ID
    ///     will be generated.
    ///   - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions
    ///     screen
    ///   - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Enrollment is complete.
    @ViewBuilder public class func smartSelfieEnrollmentScreenEnhanced(
        userId: String = generateUserId(),
        allowNewEnroll: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        skipApiSubmission: Bool = false,
        extraPartnerParams: [String: String] = [:],
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedEnhancedSelfieCaptureScreen(
            userId: userId,
            isEnroll: true,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            showInstructions: showInstructions,
            skipApiSubmission: skipApiSubmission,
            extraPartnerParams: extraPartnerParams,
            onResult: delegate
        )
    }

    /// Perform a SmartSelfie™ Authentication
    ///
    /// Docs: https://docs.usesmileid.com/products/for-individuals-kyc/biometric-authentication
    ///
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
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Authentication is complete.
    @ViewBuilder public class func smartSelfieAuthenticationScreen(
        userId: String,
        jobId: String = generateJobId(),
        allowNewEnroll: Bool = false,
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        useStrictMode _: Bool = false,
        skipApiSubmission: Bool = false,
        extraPartnerParams: [String: String] = [:],
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedSelfieCaptureScreen(
            userId: userId,
            jobId: jobId,
            isEnroll: false,
            allowNewEnroll: allowNewEnroll,
            allowAgentMode: allowAgentMode,
            showAttribution: showAttribution,
            showInstructions: showInstructions,
            extraPartnerParams: extraPartnerParams,
            skipApiSubmission: skipApiSubmission,
            onResult: delegate
        )
    }

    /// Perform a SmartSelfie™ Authentication
    ///
    /// Docs: https://docs.usesmileid.com/products/for-individuals-kyc/biometric-authentication
    ///
    /// - Parameters:
    ///   - userId: The user ID to associate with the SmartSelfie™ Enrollment. Most often, this will
    ///     correspond to a unique User ID within your own system. If not provided, a random user ID
    ///     will be generated.
    ///   - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions
    ///     screen
    ///   - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Authentication is complete.
    @ViewBuilder public class func smartSelfieAuthenticationScreenEnhanced(
        userId: String,
        allowNewEnroll: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        skipApiSubmission: Bool = false,
        extraPartnerParams: [String: String] = [:],
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedEnhancedSelfieCaptureScreen(
            userId: userId,
            isEnroll: false,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            showInstructions: showInstructions,
            skipApiSubmission: skipApiSubmission,
            extraPartnerParams: extraPartnerParams,
            onResult: delegate
        )
    }

    /// Perform a Document Verification
    /// - Parameters:
    ///   - userId: The user ID to associate with the Document Verification. Most often, this will
    ///   correspond to a unique User ID within your system. If not provided, a random user ID will
    ///    be generated.
    ///   - jobId: The job ID to associate with the Document Verification. Most often, this will
    ///   correspond to unique Job ID within your system. If not provided, a random job ID will
    ///   be generated.
    ///   - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///   - countryCode: The ISO 3166-1 alpha-3 country code of the document
    ///   - documentType: An optional string for the type of document to be captured
    ///   - idAspectRatio: An optional value for the aspect ratio of the document. If no value is,
    ///   supplied, image analysis is done to calculate the documents aspect ratio
    ///   - bypassSelfieCaptureWithFile: If provided, selfie capture will be bypassed using this
    ///   image
    ///   - enableAutoCapture: Enable or disable document auto capture
    ///   - captureBothSides: Whether to capture both sides of the ID or not. Otherwise, only the
    ///   front side will be captured. If this is true, an option to skip back side will still be
    ///   shown
    ///   - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///   displayed allowing toggling between the back camera and front camera. If not allowed, only
    ///   the front camera will be used.
    ///   - allowGalleryUpload: Whether to allow the user to upload images from their gallery or not
    ///   - showInstructions: Whether to deactivate capture screen's instructions for Document
    ///   Verification (NB! If instructions are disabled, gallery upload won't be possible)
    ///   - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///   - delegate: The delegate object that receives the result of the Document Verification
    public class func documentVerificationScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowNewEnroll: Bool = false,
        countryCode: String,
        documentType: String? = nil,
        idAspectRatio: Double? = nil,
        bypassSelfieCaptureWithFile: URL? = nil,
        enableAutoCapture: Bool = true,
        captureBothSides: Bool = true,
        allowAgentMode: Bool = false,
        allowGalleryUpload: Bool = false,
        showInstructions: Bool = true,
        showAttribution: Bool = true,
        skipApiSubmission: Bool = false,
        useStrictMode: Bool = false,
        extraPartnerParams: [String: String] = [:],
        delegate: DocumentVerificationResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedDocumentVerificationScreen(
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            userId: userId,
            jobId: jobId,
            enableAutoCapture: enableAutoCapture,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            allowGalleryUpload: allowGalleryUpload,
            allowAgentMode: allowAgentMode,
            showInstructions: showInstructions,
            skipApiSubmission: skipApiSubmission,
            useStrictMode: useStrictMode,
            extraPartnerParams: extraPartnerParams,
            onResult: delegate
        )
    }

    /// Perform an Enhanced Document Verification
    /// - Parameters:
    ///   - userId: The user ID to associate with the Document Verification. Most often, this will
    ///   correspond to a unique User ID within your system. If not provided, a random user ID will
    ///    be generated.
    ///   - jobId: The job ID to associate with the Document Verification. Most often, this will
    ///   correspond to unique Job ID within your system. If not provided, a random job ID will
    ///   be generated.
    ///   - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///   - countryCode: The ISO 3166-1 alpha-3 country code of the document
    ///   - documentType: An optional string for the type of document to be captured
    ///   - idAspectRatio: An optional value for the aspect ratio of the document. If no value is,
    ///   supplied, image analysis is done to calculate the documents aspect ratio
    ///   - bypassSelfieCaptureWithFile: If provided, selfie capture will be bypassed using this
    ///   image
    ///   - enableAutoCapture: Enable or disable document auto capture
    ///   - captureBothSides: Whether to capture both sides of the ID or not. Otherwise, only the
    ///   front side will be captured. If this is true, an option to skip back side will still be
    ///   shown
    ///  - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///   displayed allowing toggling between the back camera and front camera. If not allowed, only
    ///   the front camera will be used.
    ///   - allowGalleryUpload: Whether to allow the user to upload images from their gallery or not
    ///   - showInstructions: Whether to deactivate capture screen's instructions for Document
    ///   Verification (NB! If instructions are disabled, gallery upload won't be possible)
    ///   - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///   - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///   - extraPartnerParams: Custom values specific to partners
    ///  - consentInformation: Consent information based on when the user has
    ///  accepted consent, if they have not the default will be false
    ///  and the timestamp will be at the point of screen being shown
    ///   - delegate: The delegate object that receives the result of the Document Verification
    public class func enhancedDocumentVerificationScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowNewEnroll: Bool = false,
        countryCode: String,
        documentType: String? = nil,
        idAspectRatio: Double? = nil,
        bypassSelfieCaptureWithFile: URL? = nil,
        enableAutoCapture: Bool = true,
        captureBothSides: Bool = true,
        allowAgentMode: Bool = false,
        allowGalleryUpload: Bool = false,
        showInstructions: Bool = true,
        skipApiSubmission: Bool = false,
        showAttribution: Bool = true,
        useStrictMode: Bool = false,
        extraPartnerParams: [String: String] = [:],
        consentInformation: ConsentInformation = ConsentInformation(
            consented: ConsentedInformation(consentGrantedDate: Date().toISO8601WithMilliseconds(),
                                            personalDetails: false,
                                            contactInformation: false,
                                            documentInformation: false)
        ),
        delegate: EnhancedDocumentVerificationResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedEnhancedDocumentVerificationScreen(
            countryCode: countryCode,
            documentType: documentType,
            consentInformation: consentInformation,
            captureBothSides: captureBothSides,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            userId: userId,
            jobId: jobId,
            enableAutoCapture: enableAutoCapture,
            allowNewEnroll: allowNewEnroll,
            showAttribution: showAttribution,
            allowGalleryUpload: allowGalleryUpload,
            allowAgentMode: allowAgentMode,
            showInstructions: showInstructions,
            skipApiSubmission: skipApiSubmission,
            useStrictMode: useStrictMode,
            extraPartnerParams: extraPartnerParams,
            onResult: delegate
        )
    }

    public class func consentScreen(
        partnerIcon: UIImage,
        partnerName: String,
        productName: String,
        partnerPrivacyPolicy: URL,
        showAttribution: Bool = true,
        onConsentGranted: @escaping (ConsentInformation) -> Void,
        onConsentDenied: @escaping () -> Void
    ) -> some View {
        OrchestratedConsentScreen(
            partnerIcon: partnerIcon,
            partnerName: partnerName,
            productName: productName,
            partnerPrivacyPolicy: partnerPrivacyPolicy,
            showAttribution: showAttribution,
            onConsentGranted: onConsentGranted,
            onConsentDenied: onConsentDenied
        )
    }

    /// Perform a Biometric KYC: Verify the ID information of your user and confirm that the ID
    /// actually belongs to the user. This is achieved by comparing the user's SmartSelfie™ to the
    /// user's photo in an ID authority database
    /// - Parameters:
    ///  - idInfo: The ID information to look up in the ID Authority
    ///  - userId: The user ID to associate with the Biometric KYC. Most often, this will correspond
    ///  to a unique User ID within your own system. If not provided, a random user ID is generated
    ///  - jobId: The job ID to associate with the Biometric KYC. Most often, this will correspond
    ///  - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///  to a unique Job ID within your own system. If not provided, a random job ID is generated
    ///  - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///   displayed allowing toggling between the back camera and front camera. If not allowed, only
    ///   the front camera will be used.
    ///  - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///  - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///  - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///  - extraPartnerParams: Custom values specific to partners
    ///  - consentInformation: Consent information based on when the user has accepted consent,
    ///  if they have not the default will be false
    ///  and the timestamp will be at the point of screen being shown
    ///  - delegate: Callback to be invoked when the Biometric KYC is complete.
    public class func biometricKycScreen(
        idInfo: IdInfo,
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowNewEnroll: Bool = false,
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        useStrictMode: Bool = false,
        extraPartnerParams: [String: String] = [:],
        consentInformation: ConsentInformation = ConsentInformation(
            consented: ConsentedInformation(consentGrantedDate: Date().toISO8601WithMilliseconds(),
                                            personalDetails: false,
                                            contactInformation: false,
                                            documentInformation: false)
        ),
        delegate: BiometricKycResultDelegate
    ) -> some View {
        Metadata.shared.initialize()
        return OrchestratedBiometricKycScreen(
            idInfo: idInfo,
            consentInformation: consentInformation,
            userId: userId,
            jobId: jobId,
            allowNewEnroll: allowNewEnroll,
            showInstructions: showInstructions,
            showAttribution: showAttribution,
            allowAgentMode: allowAgentMode,
            useStrictMode: useStrictMode,
            extraPartnerParams: extraPartnerParams,
            delegate: delegate
        )
    }
}
