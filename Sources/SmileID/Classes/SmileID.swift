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
    @ObservedObject
    internal static var navigationState = NavigationViewModel()
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
        return SmileView(initialDestination: destination).environmentObject(navigationState)
    }

    public class func documentVerificationScreen(userId _: String = "user-\(UUID().uuidString)",
                                                 jobId _: String = "job-\(UUID().uuidString)",
                                                 showAttribution _: Bool = true,
                                                 showInstruction _: Bool = true,
                                                 delegate: DocumentCaptureResultDelegate)
        -> some View {
        let viewModel = DocumentCaptureViewModel()
        let destination = NavigationDestination.documentCaptureInstructionScreen(
            documentCaptureViewModel: viewModel,
            delegate: delegate)
        return SmileView(initialDestination: destination).environmentObject(navigationState)
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
        return SmileView(initialDestination: destination).environmentObject(navigationState)
    }

    public class func setEnvironment(useSandbox: Bool) {
        SmileID.useSandbox = useSandbox
    }
}
