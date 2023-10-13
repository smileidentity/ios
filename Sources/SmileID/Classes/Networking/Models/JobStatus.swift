import Foundation

public struct JobStatusRequest: Codable {
    public var userId: String
    public var jobId: String
    public var includeImageLinks: Bool
    public var includeHistory: Bool
    public var partnerId: String = SmileID.config.partnerId
    public var timestamp: String
    public var signature: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case jobId  = "job_id"
        case includeImageLinks = "image_links"
        case includeHistory = "history"
        case partnerId = "partner_id"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public struct JobStatusResponse: Codable {
    public var timestamp: String
    public var jobComplete: Bool
    public var jobSuccess: Bool
    public var code: String
    public var result: JobResult?
    public var resultString: String?
    public var history: JobResult?
    public var imageLinks: ImageLinks?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        jobComplete = try container.decode(Bool.self, forKey: .jobComplete)
        jobSuccess = try container.decode(Bool.self, forKey: .jobSuccess)
        code = try container.decode(String.self, forKey: .code)
        if let result = try? container.decodeIfPresent(JobResult.self, forKey: .result) {
            self.result = result
        }
        if let resultString = try? container.decodeIfPresent(String.self, forKey: .result) {
            self.resultString = resultString
        }
        history = try container.decodeIfPresent(JobResult.self, forKey: .history)
        imageLinks = try container.decodeIfPresent(ImageLinks.self, forKey: .imageLinks)
    }

    init(timestamp: String, jobComplete: Bool, jobSuccess: Bool, code: String) {
        self.timestamp = timestamp
        self.jobSuccess = jobSuccess
        self.jobComplete = jobComplete
        self.code = code
    }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case jobComplete = "job_complete"
        case jobSuccess = "job_success"
        case code
        case result
        case history
        case imageLinks = "image_links"
    }
}

public struct JobResult: Codable {
    public var source: String
    public var actions: Actions
    public var resultCode: Int
    public var resultText: String
    public var resultType: String
    public var smileJobId: String
    public var partnerParams: PartnerParams?
    public var confidence: Double
    public var isFinalResult: Bool
    public var isMachineResult: Bool

    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case actions = "Actions"
        case resultCode = "ResultCode"
        case resultText = "ResultText"
        case resultType = "ResultType"
        case smileJobId = "SmileJobID"
        case partnerParams = "PartnerParams"
        case confidence = "ConfidenceValue"
        case isFinalResult = "IsFinalResult"
        case isMachineResult = "IsMachineResult"
    }
}

public struct Actions: Codable {
    public var humanReviewCompare: ActionResult
    public var humanReviewLivenessCheck: ActionResult
    public var humanReviewSelfieCheck: ActionResult
    public var humanReviewUpdateSelfie: ActionResult
    public var livenessCheck: ActionResult
    public var selfieCheck: ActionResult
    public var registerSelfie: ActionResult
    public var returnPersonalInfo: ActionResult
    public var selfieProvided: ActionResult
    public var selfieToIdAuthorityCapture: ActionResult
    public var selfieToIdCardCompare: ActionResult
    public var selfieToRegisteredSelfieCompare: ActionResult
    public var updateRegisteredSelfieOnFile: ActionResult
    public var verifyIdNumber: ActionResult

    enum CodingKeys: String, CodingKey {
        case humanReviewCompare = "Human_Review_Compare"
        case humanReviewLivenessCheck = "Human_Review_Liveness_Check"
        case humanReviewSelfieCheck = "Human_Review_Selfie_Check"
        case humanReviewUpdateSelfie = "Human_Review_Update_Selfie"
        case livenessCheck = "Liveness_Check"
        case selfieCheck = "Selfie_Check"
        case registerSelfie = "Register_Selfie"
        case returnPersonalInfo = "Return_Personal_Info"
        case selfieProvided = "Selfie_Provided"
        case selfieToIdAuthorityCapture = "Selfie_To_ID_Authority_Compare"
        case selfieToIdCardCompare = "Selfie_To_ID_Card_Compare"
        case selfieToRegisteredSelfieCompare = "Selfie_To_Registered_Selfie_Compare"
        case updateRegisteredSelfieOnFile = "Update_Registered_Selfie_On_File"
        case verifyIdNumber = "Verify_ID_Number"
    }
}

public enum ActionResult: String, Codable {
    case passed = "Passed"
    case completed = "Completed"
    case approved = "Approved"
    case verified = "Verified"
    case provisionallyApproved = "Provisionally Approved"
    case returned = "Returned"
    case notReturned = "Not Returned"
    case failed = "Failed"
    case rejected = "Rejected"
    case underReview = "Under Review"
    case unableToDetermine = "Unable To Determine"
    case notApplicable = "Not Applicable"
    case notVerified = "Not Verified"
    case notDone = "Not Done"
    case issuerUnavailable = "Issuer Unavailable"
}

public struct ImageLinks: Codable {
    public var selfieImageUrl: String?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case selfieImageUrl = "selfie_image"
        case error
    }
}
