import Foundation

public struct DocumentVerificationConfig {
    let userId: String
    let jobId: String
    let consentInformation: ConsentInformation?
    let allowNewEnroll: Bool
    let countryCode: String
    let documentType: String?
    let idAspectRatio: Double?
    let bypassSelfieCaptureWithFile: URL?
    let captureBothSides: Bool
    let allowAgentMode: Bool
    let allowGalleryUpload: Bool
    let showInstructions: Bool
    let showAttribution: Bool
    let skipApiSubmission: Bool
    let useStrictMode: Bool
    let extraPartnerParams: [String: String]

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
    public init(
        userId: String = generateUserId(),
        jobId: String = generateJobId(),
        consentInformation: ConsentInformation? = nil,
        allowNewEnroll: Bool = false,
        countryCode: String,
        documentType: String? = nil,
        idAspectRatio: Double? = nil,
        bypassSelfieCaptureWithFile: URL? = nil,
        captureBothSides: Bool = true,
        allowAgentMode: Bool = false,
        allowGalleryUpload: Bool = false,
        showInstructions: Bool = true,
        showAttribution: Bool = true,
        skipApiSubmission: Bool = false,
        useStrictMode: Bool = false,
        extraPartnerParams: [String: String] = [:]
    ) {
        self.userId = userId
        self.jobId = jobId
        self.consentInformation = consentInformation
        self.allowNewEnroll = allowNewEnroll
        self.countryCode = countryCode
        self.documentType = documentType
        self.idAspectRatio = idAspectRatio
        self.bypassSelfieCaptureWithFile = bypassSelfieCaptureWithFile
        self.captureBothSides = captureBothSides
        self.allowAgentMode = allowAgentMode
        self.allowGalleryUpload = allowGalleryUpload
        self.showInstructions = showInstructions
        self.showAttribution = showAttribution
        self.skipApiSubmission = skipApiSubmission
        self.useStrictMode = useStrictMode
        self.extraPartnerParams = extraPartnerParams
    }
}
