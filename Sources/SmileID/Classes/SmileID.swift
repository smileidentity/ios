// swiftlint:disable force_try
import Foundation
import SwiftUI
import UIKit

public class SmileID {
    @Injected var injectedApi: SmileIDServiceable
    public static var api: SmileIDServiceable {
        return SmileID.instance.injectedApi
    }

    public static var configuration: Config {
        return config
    }

    internal static let instance: SmileID = {
        let container = DependencyContainer.shared
        container.register(SmileIDServiceable.self) { SmileIDService() }
        container.register(RestServiceClient.self) { URLSessionRestServiceClient() }
        container.register(ServiceHeaderProvider.self) { DefaultServiceHeaderProvider() }
        let instance = SmileID()
        return instance
    }()

    private init() {}
    public static let version = "10.0.0-beta07"
    public private(set) static var config: Config!
    public private(set) static var useSandbox = true
    public private(set) static var theme: SmileIdTheme = DefaultTheme()
    internal private(set) static var localizableStrings: SmileIDLocalizableStrings?
    @ObservedObject internal static var router = Router<NavigationDestination>()

    /// This method initilizes SmileID. Invoke this method once in your applicaion lifecylce
    /// before calling any other SmileID methods.
    /// - Parameters:
    ///   - config: The smile config file. If no value is supplied, we check the app's main bundle for a `smile_config.json` file.
    ///   - useSandbox: A boolean to enable the sandbox environment or not
    public class func initialize(config: Config = try! Config(url: Bundle.main.url(forResource: "smile_config",
                                                                                   withExtension: "json")!),
                                 useSandbox: Bool = true) {
        self.config = config
        self.useSandbox = useSandbox
        SmileIDResourcesHelper.registerFonts()
    }

    public class func apply(_ theme: SmileIdTheme) {
        self.theme = theme
    }

    /// Apply localizable strings
    /// - Parameter localizableStrings: A `SmileIDLocalizableStrings`  used to override all copy used within the SDK.
    ///   if no value is set, the default copy will be used.
    public class func apply(_ localizableStrings: SmileIDLocalizableStrings) {
        self.localizableStrings = localizableStrings
    }

    public class func smartSelfieEnrollmentScreen(userId: String = "user-\(UUID().uuidString)",
                                                  jobId: String = "job-\(UUID().uuidString)",
                                                  allowAgentMode: Bool = false,
                                                  showAttribution: Bool = true,
                                                  showInstruction: Bool = true,
                                                  delegate: SmartSelfieResultDelegate)
        -> some View {
        let viewModel = SelfieCaptureViewModel(userId: userId,
                                               jobId: jobId,
                                               isEnroll: true,
                                               allowsAgentMode: allowAgentMode,
                                               showAttribution: showAttribution)
        let destination: NavigationDestination = showInstruction ?
            .selfieInstructionScreen(selfieCaptureViewModel: viewModel, delegate: delegate) :
            .selfieCaptureScreen(selfieCaptureViewModel: viewModel, delegate: delegate)
        return SmileView(initialDestination: destination).environmentObject(router)
    }

    /// Perform a Document Verification
    /// - Parameters:
    ///   - userId: The user ID to associate with the Document Verification. Most often, this will correspond to
    ///   a unique User ID within your system. If not provided, a random user ID will be generated.
    ///   - jobId: The job ID to associate with the Document Verification. Most often, this will correspond to a
    ///   unique Job ID within your system. If not provided, a random job ID will be generated.
    ///   - idType: The type of ID to be captured
    ///   - selfie: A jpg selfie where if provided, the user will not be propmpted to capture a selfie and this file
    ///   will be used as the selfie image.
    ///   - captureBothSides: Whether to capture both sides of the ID or not. Otherwise, only the front side
    ///   will be captured
    ///   - allowGalleryUpload: Whether to allow the user to upload images from their gallery or not
    ///   - showInstructions: Whether to deactivate capture screen's instructions for Document Verification
    ///   (NB! If instructions are disabled, gallery upload won't be possible)
    ///   - showAttribution: Whether to show the Smile ID attribution or not on the Instructions screen
    ///   - delegate: The delegate object that recieves the result of the Document Verification
    public class func documentVerificationScreen(userId: String = "user-\(UUID().uuidString)",
                                                 jobId: String = "job-\(UUID().uuidString)",
                                                 idType: Document,
                                                 selfie: Data? = nil,
                                                 captureBothSides: Bool = true,
                                                 allowGalleryUpload: Bool = false,
                                                 showInstructions: Bool = false,
                                                 showAttribution: Bool = true,
                                                 delegate: DocumentCaptureResultDelegate)
        -> some View {
            let viewModel = DocumentCaptureViewModel(userId: userId,
                                                     jobId: jobId,
                                                     document: idType,
                                                     selfie: selfie,
                                                     captureBothSides: captureBothSides,
                                                     showAttribution: showAttribution,
                                                     allowGalleryUpload: allowGalleryUpload)

        let destination = showInstructions ? NavigationDestination.documentFrontCaptureInstructionScreen(
            documentCaptureViewModel: viewModel,
            delegate: delegate) : NavigationDestination.documentCaptureScreen(documentCaptureViewModel: viewModel,
                                                                              delegate: delegate)
        return SmileView(initialDestination: destination).environmentObject(router)
    }

    public class func smartSelfieAuthenticationScreen(userId: String,
                                                      jobId: String = "job-\(UUID().uuidString)",
                                                      allowAgentMode: Bool = false,
                                                      showAttribution: Bool = true,
                                                      showInstruction: Bool = true,
                                                      delegate: SmartSelfieResultDelegate)
        -> some View {
        let viewModel = SelfieCaptureViewModel(userId: userId,
                                               jobId: jobId,
                                               isEnroll: false,
                                               allowsAgentMode: allowAgentMode,
                                               showAttribution: showAttribution)
        let destination: NavigationDestination = showInstruction ?
                .selfieInstructionScreen(selfieCaptureViewModel: viewModel, delegate: delegate) :
            .selfieCaptureScreen(selfieCaptureViewModel: viewModel, delegate: delegate)
            return SmileView(initialDestination: destination)
                .environmentObject(router)

    }

    public class func setEnvironment(useSandbox: Bool) {
        SmileID.useSandbox = useSandbox
    }
}
