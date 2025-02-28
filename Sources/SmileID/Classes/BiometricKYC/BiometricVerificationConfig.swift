import Foundation

public struct BiometricVerificationConfig {
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let idInfo: IdInfo
    let useStrictMode: Bool
    let allowAgentMode: Bool
    let showAttribution: Bool
    let showInstructions: Bool
    let skipApiSubmission: Bool
    let consentInformation: ConsentInformation
    let extraPartnerParams: [String: String]

    /// - Parameters:
    ///  - userId: The user ID to associate with the Biometric KYC. Most often, this will correspond
    ///  to a unique User ID within your own system. If not provided, a random user ID is generated
    ///  - jobId: The job ID to associate with the Biometric KYC. Most often, this will correspond
    ///  - idInfo: The ID information to look up in the ID Authority
    ///  - allowNewEnroll:  Allows a partner to enroll the same user id again
    ///  to a unique Job ID within your own system. If not provided, a random job ID is generated
    ///  - allowAgentMode: Whether to allow Agent Mode or not. If allowed, a switch will be
    ///   displayed allowing toggling between the back camera and front camera. If not allowed, only
    ///   the front camera will be used.
    ///  - showAttribution: Whether to show the Smile ID attribution on the Instructions screen
    ///  - showInstructions: Whether to deactivate capture screen's instructions for SmartSelfie.
    ///  - skipApiSubmission: Whether to skip api submission to SmileID and return only captured images
    ///  - consentInformation: We need you to pass the consent from the user
    ///  - extraPartnerParams: Custom values specific to partners
    public init(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        allowNewEnroll: Bool,
        idInfo: IdInfo,
        useStrictMode: Bool,
        allowAgentMode: Bool,
        showAttribution: Bool,
        showInstructions: Bool,
        skipApiSubmission: Bool,
        consentInformation: ConsentInformation,
        extraPartnerParams: [String : String]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.idInfo = idInfo
        self.useStrictMode = useStrictMode
        self.allowAgentMode = allowAgentMode
        self.showAttribution = showAttribution
        self.showInstructions = showInstructions
        self.skipApiSubmission = skipApiSubmission
        self.consentInformation = consentInformation
        self.extraPartnerParams = extraPartnerParams
    }
}
