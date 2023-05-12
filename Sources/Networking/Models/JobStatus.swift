import Foundation

public struct JobStatusRequest: Codable {
    var userId: String
    var jobId: String
    var includeImageLinks: Bool
    var includeHistory: Bool
    var partnerId: String = SmileIdentity.config.partnerId
    var timestamp: String
    var signature: String

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
    var timestamp: String
    var jobComplete: Bool
    var jobSuccess: Bool
    var code: String
    var result: JobResult?
    var resultString: String?
    var history: JobResult?
    var imageLinks: ImageLinks?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.jobComplete = try container.decode(Bool.self, forKey: .jobComplete)
        self.jobSuccess = try container.decode(Bool.self, forKey: .jobSuccess)
        self.code = try container.decode(String.self, forKey: .code)
        if let result = try? container.decodeIfPresent(JobResult.self, forKey: .result) {
            self.result = result
        }
        if let resultString = try? container.decodeIfPresent(String.self, forKey: .result) {
            self.resultString = resultString
        }
        self.history = try container.decodeIfPresent(JobResult.self, forKey: .history)
        self.imageLinks = try container.decodeIfPresent(ImageLinks.self, forKey: .imageLinks)
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

struct JobResult: Codable {
    var source: String
    var actions: Actions
    var resultCode: Int
    var resultText: String
    var resultType: String
    var smileJobId: String
    var partnerParams: PartnerParams?
    var confidence: Double
    var isFinalResult: Bool
    var isMachineResult: Bool

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

struct Actions: Codable {
    var humanReviewCompare: ActionResult
    var humanReviewLivenessCheck: ActionResult
    var humanReviewSelfieCheck: ActionResult
    var humanReviewUpdateSelfie: ActionResult
    var livenessCheck: ActionResult
    var selfieCheck: ActionResult
    var registerSelfie: ActionResult
    var returnPersonalInfo: ActionResult
    var selfieProvided: ActionResult
    var selfieToIdAuthorityCapture: ActionResult
    var selfieToIdCardCompare: ActionResult
    var selfieToRegisteredSelfieCompare: ActionResult
    var updateRegisteredSelfieOnFile: ActionResult
    var verifyIdNumber: ActionResult

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

enum ActionResult: String, Codable {
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
    case notApplicable = "Not Applicaple"
    case notVerified = "Not Verified"
    case notDone = "Not Done"
    case issuerUnavailable = "Issuer Unavailable"
}

struct ImageLinks: Codable {
    var selfieImageUrl: String?
    var error: String?

    enum CodingKeys: String, CodingKey {
        case selfieImageUrl = "selfie_image"
        case error
    }
}
