import Foundation
import SwiftUI
import UIKit

public class SmileID {
    public static let version = "10.0.0-beta09"
    @Injected var injectedApi: SmileIDServiceable
    public static var configuration: Config { config }

    public static var api: SmileIDServiceable { SmileID.instance.injectedApi }

    internal static let instance: SmileID = {
        let container = DependencyContainer.shared
        container.register(SmileIDServiceable.self) { SmileIDService() }
        container.register(RestServiceClient.self) { URLSessionRestServiceClient() }
        container.register(ServiceHeaderProvider.self) { DefaultServiceHeaderProvider() }
        let instance = SmileID()
        return instance
    }()

    private init() {}

    public private(set) static var config: Config!
    public private(set) static var useSandbox = true
    internal static var apiKey: String?
    public private(set) static var theme: SmileIdTheme = DefaultTheme()
    internal private(set) static var localizableStrings: SmileIDLocalizableStrings?
    @ObservedObject internal static var router = Router<NavigationDestination>()

    /// This method initializes SmileID. Invoke this method once in your application lifecylce
    /// before calling any other SmileID methods.
    /// - Parameters:
    ///   - config: The smile config file. If no value is supplied, we check the app's main bundle
    ///    for a `smile_config.json` file.
    ///   - useSandbox: A boolean to enable the sandbox environment or not
    public class func initialize(
        config: Config = getConfig(),
        useSandbox: Bool = true
    ) {
        initialize(apiKey: nil, config: config, useSandbox: useSandbox)
    }

    /// This method initializes SmileID. Invoke this method once in your application lifecylce
    /// before calling any other SmileID methods.
    /// - Parameters:
    ///   - apiKey: The api key displayed on your partner portal
    ///   - config: The smile config file. If no value is supplied, we check the app's main bundle
    ///    for a `smile_config.json` file.
    ///   - useSandbox: A boolean to enable the sandbox environment or not
    public class func initialize(
        apiKey: String? = nil,
        config: Config = getConfig(),
        useSandbox: Bool = true
    ) {
        self.config = config
        self.useSandbox = useSandbox
        self.apiKey = apiKey
        SmileIDResourcesHelper.registerFonts()
    }

    /// Set the environment
    /// - Parameter useSandbox: A boolean to enable the sandbox environment or not
    public class func setEnvironment(useSandbox: Bool) {
        SmileID.useSandbox = useSandbox
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

    /// Load the Config object from a json file
    /// - Parameter resourceName: The name of the json file. Defaults to `smile_config`
    /// - Returns: A `Config` object
    public static func getConfig(from resourceName: String = "smile_config") -> Config {
        // swiftlint:disable force_try
        try! Config(url: Bundle.main.url(forResource: resourceName, withExtension: "json")!)
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
    ///   - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///     displayed allowing toggling between the back camera and front camera. If not allowed,
    ///     only the front camera will be used.
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions
    ///     screen
    ///   - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Enrollment is complete.
    public class func smartSelfieEnrollmentScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        let viewModel = SelfieCaptureViewModel(
            userId: userId,
            jobId: jobId,
            isEnroll: true,
            allowsAgentMode: allowAgentMode,
            showAttribution: showAttribution
        )
        let destination: NavigationDestination = showInstructions ?
            .selfieInstructionScreen(selfieCaptureViewModel: viewModel, delegate: delegate) :
            .selfieCaptureScreen(selfieCaptureViewModel: viewModel, delegate: delegate)
        return SmileView(initialDestination: destination).environmentObject(router)
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
    ///   - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///     displayed allowing toggling between the back camera and front camera. If not allowed,
    ///     only the front camera will be used.
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions
    ///     screen
    ///   - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///   - delegate: Callback to be invoked when the SmartSelfie™ Authentication is complete.
    public class func smartSelfieAuthenticationScreen(
        userId: String,
        jobId: String = generateJobId(),
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        delegate: SmartSelfieResultDelegate
    ) -> some View {
        let viewModel = SelfieCaptureViewModel(
            userId: userId,
            jobId: jobId,
            isEnroll: false,
            allowsAgentMode: allowAgentMode,
            showAttribution: showAttribution
        )
        let destination: NavigationDestination = showInstructions ?
            .selfieInstructionScreen(selfieCaptureViewModel: viewModel, delegate: delegate) :
            .selfieCaptureScreen(selfieCaptureViewModel: viewModel, delegate: delegate)
        return SmileView(initialDestination: destination).environmentObject(router)
    }

    /// Perform a Document Verification
    /// - Parameters:
    ///   - userId: The user ID to associate with the Document Verification. Most often, this will
    ///   correspond to a unique User ID within your system. If not provided, a random user ID will
    ///    be generated.
    ///   - jobId: The job ID to associate with the Document Verification. Most often, this will
    ///   correspond to unique Job ID within your system. If not provided, a random job ID will
    ///   be generated.
    ///   - countryCode: The ISO 3166-1 alpha-3 country code of the document
    ///   - documentType: An optional string for the type of document to be captured
    ///   - idAspectRatio: An optional value for the aspect ratio of the document. If no value is,
    ///   supplied, image analysis is done to calculate the documents aspect ratio
    ///   - bypassSelfieCaptureWithFile: If provided, selfie capture will be bypassed using this
    ///   image
    ///   - captureBothSides: Whether to capture both sides of the ID or not. Otherwise, only the
    ///   front side will be captured. If this is true, an option to skip back side will still be
    ///   shown
    ///   - allowGalleryUpload: Whether to allow the user to upload images from their gallery or not
    ///   - showInstructions: Whether to deactivate capture screen's instructions for Document
    ///   Verification (NB! If instructions are disabled, gallery upload won't be possible)
    ///   - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///   - delegate: The delegate object that receives the result of the Document Verification
    public class func documentVerificationScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        countryCode: String,
        documentType: String? = nil,
        idAspectRatio: Double? = nil,
        bypassSelfieCaptureWithFile: URL? = nil,
        captureBothSides: Bool = true,
        allowGalleryUpload: Bool = false,
        showInstructions: Bool = true,
        showAttribution: Bool = true,
        delegate: DocumentVerificationResultDelegate
    ) -> some View {
        OrchestratedDocumentVerificationScreen(
            countryCode: countryCode,
            documentType: documentType,
            captureBothSides: captureBothSides,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            userId: userId,
            jobId: jobId,
            showAttribution: showAttribution,
            allowGalleryUpload: allowGalleryUpload,
            showInstructions: showInstructions,
            onResult: delegate
        ).environmentObject(router)
    }

    /// Perform an Enhanced Document Verification
    /// - Parameters:
    ///   - userId: The user ID to associate with the Document Verification. Most often, this will
    ///   correspond to a unique User ID within your system. If not provided, a random user ID will
    ///    be generated.
    ///   - jobId: The job ID to associate with the Document Verification. Most often, this will
    ///   correspond to unique Job ID within your system. If not provided, a random job ID will
    ///   be generated.
    ///   - countryCode: The ISO 3166-1 alpha-3 country code of the document
    ///   - documentType: An optional string for the type of document to be captured
    ///   - idAspectRatio: An optional value for the aspect ratio of the document. If no value is,
    ///   supplied, image analysis is done to calculate the documents aspect ratio
    ///   - bypassSelfieCaptureWithFile: If provided, selfie capture will be bypassed using this
    ///   image
    ///   - captureBothSides: Whether to capture both sides of the ID or not. Otherwise, only the
    ///   front side will be captured. If this is true, an option to skip back side will still be
    ///   shown
    ///   - allowGalleryUpload: Whether to allow the user to upload images from their gallery or not
    ///   - showInstructions: Whether to deactivate capture screen's instructions for Document
    ///   Verification (NB! If instructions are disabled, gallery upload won't be possible)
    ///   - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///   - delegate: The delegate object that receives the result of the Document Verification
    public class func enhancedDocumentVerificationScreen(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        countryCode: String,
        documentType: String? = nil,
        idAspectRatio: Double? = nil,
        bypassSelfieCaptureWithFile: URL? = nil,
        captureBothSides: Bool = true,
        allowGalleryUpload: Bool = false,
        showInstructions: Bool = true,
        showAttribution: Bool = true,
        delegate: DocumentVerificationResultDelegate
    ) -> some View {
        // TODO: parametrize
        documentVerificationScreen(
            userId: userId,
            jobId: jobId,
            countryCode: countryCode,
            documentType: documentType,
            idAspectRatio: idAspectRatio,
            bypassSelfieCaptureWithFile: bypassSelfieCaptureWithFile,
            captureBothSides: captureBothSides,
            allowGalleryUpload: allowGalleryUpload,
            showInstructions: showInstructions,
            showAttribution: showAttribution,
            delegate: delegate
        ).environmentObject(router)
    }
}
