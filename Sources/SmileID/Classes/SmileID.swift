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
    public static let version = "10.0.0-beta02"
    internal static var config: Config!
    internal static var useSandbox = true
    internal static let navigation = NavigationHelper()
    public private(set) static var theme: SmileIdTheme = DefaultTheme()

    public class func initialize(config: Config, useSandbox: Bool = true) {
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
        -> some View
    {
        let viewModel = SelfieCaptureViewModel(userId: userId,
                                               jobId: jobId,
                                               isEnroll: true,
                                               allowsAgentMode: allowAgentMode,
                                               showAttribution: showAttribution)
        showInstruction ? navigation.navigate(to: .selfieInstructionScreen)
            : navigation.navigate(to: .selfieCaptureScreen)
        return SmileUIView {
            if showInstruction {
                SmartSelfieInstructionsView(viewModel: viewModel, delegate: delegate)
            } else {
                SelfieCaptureView(viewModel: viewModel, delegate: delegate)
            }
        }.environmentObject(navigation)
    }

    public class func documentVerificationScreen(userId _: String = "user-\(UUID().uuidString)",
                                                 jobId _: String = "job-\(UUID().uuidString)",
                                                 showAttribution _: Bool = true,
                                                 showInstruction: Bool = true,
                                                 delegate: DocumentCaptureResultDelegate)
        -> some View
    {
        showInstruction ? navigation.navigate(to: .documentCaptureInstructionScreen)
            : navigation.navigate(to: .documentCaptureScreen)
        let viewModel = DocumentCaptureViewModel()
        return SmileUIView {
            if showInstruction {
                DocumentCaptureInstructionsView(viewModel: viewModel, delegate: delegate)
            } else {
                // TODO: integrate with Jubril's view here
                DocumentCaptureInstructionsView(viewModel: viewModel, delegate: delegate)
            }
        }.environmentObject(navigation)
    }

    public class func smartSelfieAuthenticationScreen(userId: String,
                                                      jobId: String = "job-\(UUID().uuidString)",
                                                      allowAgentMode: Bool = false,
                                                      showAttribution: Bool = true,
                                                      showInstruction: Bool = true,
                                                      delegate: SmartSelfieResultDelegate)
        -> some View
    {
        showInstruction ? navigation.navigate(to: .selfieInstructionScreen)
            : navigation.navigate(to: .selfieCaptureScreen)
        let viewModel = SelfieCaptureViewModel(userId: userId,
                                               jobId: jobId,
                                               isEnroll: false,
                                               allowsAgentMode: allowAgentMode,
                                               showAttribution: showAttribution)
        return SmileUIView {
            if showInstruction {
                SmartSelfieInstructionsView(viewModel: viewModel, delegate: delegate)
            } else {
                SelfieCaptureView(viewModel: viewModel, delegate: delegate)
            }
        }.environmentObject(navigation)
    }

    public class func setEnvironment(useSandbox: Bool) {
        SmileID.useSandbox = useSandbox
    }
}
