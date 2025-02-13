import Foundation

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
        isEnroll: Bool = true,
        allowNewEnroll: Bool = false,
        allowAgentMode: Bool = false,
        showAttribution: Bool = true,
        showInstructions: Bool = true,
        extraPartnerParams: [String: String] = [:],
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
