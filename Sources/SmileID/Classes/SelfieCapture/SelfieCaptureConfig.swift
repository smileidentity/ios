import Foundation

public struct SelfieCaptureConfig {
    let isEnroll: Bool
    let userId: String
    let jobId: String
    let allowNewEnroll: Bool
    let skipApiSubmission: Bool
    let useStrictMode: Bool
    let allowAgentMode: Bool
    let showAttribution: Bool
    let showInstructions: Bool
    let extraPartnerParams: [String: String]
}
