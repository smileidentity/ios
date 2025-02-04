import Foundation

public struct JobStatusRequest: Codable {
    public var userId: String
    public var jobId: String
    public var includeImageLinks: Bool
    public var includeHistory: Bool
    public var partnerId: String = SmileID.config.partnerId
    public var timestamp: String
    public var signature: String

    public init(
        userId: String,
        jobId: String,
        includeImageLinks: Bool = false,
        includeHistory: Bool = false,
        partnerId: String = SmileID.config.partnerId,
        timestamp: String = Date().toISO8601WithMilliseconds(),
        signature: String = ""
    ) {
        self.userId = userId
        self.jobId = jobId
        self.includeImageLinks = includeImageLinks
        self.includeHistory = includeHistory
        self.partnerId = partnerId
        self.timestamp = timestamp
        self.signature = signature
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case jobId = "job_id"
        case includeImageLinks = "image_links"
        case includeHistory = "history"
        case partnerId = "partner_id"
        case timestamp = "timestamp"
        case signature = "signature"
    }
}

public typealias SmartSelfieJobStatusResponse = JobStatusResponse<SmartSelfieJobResult>
public typealias DocumentVerificationJobStatusResponse =
    JobStatusResponse<DocumentVerificationJobResult>
public typealias EnhancedDocumentVerificationJobStatusResponse =
    JobStatusResponse<EnhancedDocumentVerificationJobResult>
public typealias BiometricKycJobStatusResponse = JobStatusResponse<BiometricKycJobResult>

public final class JobStatusResponse<T: JobResult>: Codable {
    public let timestamp: String
    public let jobComplete: Bool
    public let jobSuccess: Bool
    public let code: String
    public let result: T?
    public let resultString: String?
    public let history: [T]?
    public let imageLinks: ImageLinks?

    internal init(jobComplete: Bool = true) {
        self.jobComplete = jobComplete
        timestamp = ""
        jobSuccess = true
        code = "0"
        result = nil
        resultString = nil
        history = nil
        imageLinks = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        jobComplete = try container.decode(Bool.self, forKey: .jobComplete)
        jobSuccess = try container.decode(Bool.self, forKey: .jobSuccess)
        code = try container.decode(String.self, forKey: .code)
        result = try? container.decodeIfPresent(T.self, forKey: .result)
        resultString = try? container.decodeIfPresent(String.self, forKey: .result)
        history = try container.decodeIfPresent([T].self, forKey: .history)
        imageLinks = try container.decodeIfPresent(ImageLinks.self, forKey: .imageLinks)
    }

    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case jobComplete = "job_complete"
        case jobSuccess = "job_success"
        case code = "code"
        case result
        case resultString
        case history = "history"
        case imageLinks = "image_links"
    }
}

public class JobResult: Codable {
    public let actions: Actions
    public let resultCode: String
    public let resultText: String
    public let smileJobId: String
    public let partnerParams: PartnerParams

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actions = try container.decode(Actions.self, forKey: .actions)
        resultCode = try container.decode(String.self, forKey: .resultCode)
        resultText = try container.decode(String.self, forKey: .resultText)
        smileJobId = try container.decode(String.self, forKey: .smileJobId)
        partnerParams = try container.decode(PartnerParams.self, forKey: .partnerParams)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(actions, forKey: .actions)
        try container.encode(resultCode, forKey: .resultCode)
        try container.encode(resultText, forKey: .resultText)
        try container.encode(smileJobId, forKey: .smileJobId)
        try container.encode(partnerParams, forKey: .partnerParams)
    }

    enum CodingKeys: String, CodingKey {
        case actions = "Actions"
        case resultCode = "ResultCode"
        case resultText = "ResultText"
        case smileJobId = "SmileJobID"
        case partnerParams = "PartnerParams"
        case confidence = "ConfidenceValue"
        case country = "Country"
        case idType = "IDType"
        case idNumber = "IDNumber"
        case fullName = "FullName"
        case dob = "DOB"
        case gender = "Gender"
        case expirationDate = "ExpirationDate"
        case documentImageBase64 = "Document"
        case phoneNumber = "PhoneNumber"
        case phoneNumber2 = "PhoneNumber2"
        case address = "Address"
        case antifraud = "Antifraud"
        case photoBase64 = "Photo"
        case fullData = "FullData"
        case secondaryIdNumber = "Secondary_ID_Number"
        case idNumberPreviouslyRegistered = "IDNumberPreviouslyRegistered"
        case previousRegistrantsUserIds = "UserIDsOfPreviousRegistrants"
    }
}

public class SmartSelfieJobResult: JobResult {
    public let confidence: Double?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let confidenceValue = try container.decodeIfPresent(String.self, forKey: .confidence) else {
            throw SmileIDError.unknown("Error decoding .confidenceValue")
        }
        self.confidence =  Double(confidenceValue)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try super.encode(to: encoder)
    }
}

public class BiometricKycJobResult: JobResult {
    public let antifraud: Antifraud?
    public let dob: String?
    public let photoBase64: String?
    public let gender: String?
    public let idType: String?
    public let address: String?
    public let country: String?
    public let documentImageBase64: String?
    public let fullData: FlexibleDictionary?
    public let fullName: String?
    public let idNumber: String?
    public let phoneNumber: String?
    public let phoneNumber2: String?
    public let expirationDate: String?
    public let secondaryIdNumber: String?
    public let idNumberPreviouslyRegistered: Bool?
    public let previousRegistrantsUserIds: [String]?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        antifraud = try container.decodeIfPresent(Antifraud.self, forKey: .antifraud)
        dob = try container.decodeIfPresent(String.self, forKey: .dob)
        photoBase64 = try container.decodeIfPresent(String.self, forKey: .photoBase64)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        idType = try container.decodeIfPresent(String.self, forKey: .idType)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        documentImageBase64 = try container.decodeIfPresent(
            String.self, forKey: .documentImageBase64
        )
        fullData = try container.decodeIfPresent(FlexibleDictionary.self, forKey: .fullData)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        idNumber = try container.decodeIfPresent(String.self, forKey: .idNumber)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        phoneNumber2 = try container.decodeIfPresent(String.self, forKey: .phoneNumber2)
        expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        secondaryIdNumber = try container.decodeIfPresent(String.self, forKey: .secondaryIdNumber)
        idNumberPreviouslyRegistered = try container.decodeIfPresent(
            Bool.self, forKey: .idNumberPreviouslyRegistered
        )
        previousRegistrantsUserIds = try container.decodeIfPresent(
            [String].self, forKey: .previousRegistrantsUserIds
        )
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(antifraud, forKey: .antifraud)
        try container.encode(dob, forKey: .dob)
        try container.encode(photoBase64, forKey: .photoBase64)
        try container.encode(gender, forKey: .gender)
        try container.encode(idType, forKey: .idType)
        try container.encode(address, forKey: .address)
        try container.encode(country, forKey: .country)
        try container.encode(documentImageBase64, forKey: .documentImageBase64)
        try container.encode(fullData, forKey: .fullData)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(idNumber, forKey: .idNumber)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(phoneNumber2, forKey: .phoneNumber2)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(secondaryIdNumber, forKey: .secondaryIdNumber)
        try container.encode(idNumberPreviouslyRegistered, forKey: .idNumberPreviouslyRegistered)
        try container.encode(previousRegistrantsUserIds, forKey: .previousRegistrantsUserIds)
        try super.encode(to: encoder)
    }
}

public class DocumentVerificationJobResult: JobResult {
    public let country: String?
    public let idType: String?
    public let idNumber: String?
    public let fullName: String?
    public let dob: String?
    public let gender: String?
    public let expirationDate: String?
    public let documentImageBase64: String?
    public let phoneNumber: String?
    public let phoneNumber2: String?
    public let address: String?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        idType = try container.decodeIfPresent(String.self, forKey: .idType)
        idNumber = try container.decodeIfPresent(String.self, forKey: .idNumber)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        dob = try container.decodeIfPresent(String.self, forKey: .dob)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        documentImageBase64 = try container.decodeIfPresent(
            String.self, forKey: .documentImageBase64
        )
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        phoneNumber2 = try container.decodeIfPresent(String.self, forKey: .phoneNumber2)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        try super.init(from: decoder)
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(country, forKey: .country)
        try container.encode(idType, forKey: .idType)
        try container.encode(idNumber, forKey: .idNumber)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(dob, forKey: .dob)
        try container.encode(gender, forKey: .gender)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(documentImageBase64, forKey: .documentImageBase64)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(phoneNumber2, forKey: .phoneNumber2)
        try container.encode(address, forKey: .address)
        try super.encode(to: encoder)
    }
}

public class EnhancedDocumentVerificationJobResult: JobResult {
    public let antifraud: Antifraud?
    public let dob: String?
    public let photoBase64: String?
    public let gender: String?
    public let idType: String?
    public let address: String?
    public let country: String?
    public let documentImageBase64: String?
    public let fullData: FlexibleDictionary?
    public let fullName: String?
    public let idNumber: String?
    public let phoneNumber: String?
    public let phoneNumber2: String?
    public let expirationDate: String?
    public let secondaryIdNumber: String?
    public let idNumberPreviouslyRegistered: Bool?
    public let previousRegistrantsUserIds: [String]?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        antifraud = try container.decodeIfPresent(Antifraud.self, forKey: .antifraud)
        dob = try container.decodeIfPresent(String.self, forKey: .dob)
        photoBase64 = try container.decodeIfPresent(String.self, forKey: .photoBase64)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        idType = try container.decodeIfPresent(String.self, forKey: .idType)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        documentImageBase64 = try container.decodeIfPresent(
            String.self, forKey: .documentImageBase64
        )
        fullData = try container.decodeIfPresent(FlexibleDictionary.self, forKey: .fullData)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        idNumber = try container.decodeIfPresent(String.self, forKey: .idNumber)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        phoneNumber2 = try container.decodeIfPresent(String.self, forKey: .phoneNumber2)
        expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        secondaryIdNumber = try container.decodeIfPresent(String.self, forKey: .secondaryIdNumber)
        idNumberPreviouslyRegistered = try container.decodeIfPresent(
            Bool.self, forKey: .idNumberPreviouslyRegistered
        )
        previousRegistrantsUserIds = try container.decodeIfPresent(
            [String].self, forKey: .previousRegistrantsUserIds
        )
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(antifraud, forKey: .antifraud)
        try container.encode(dob, forKey: .dob)
        try container.encode(photoBase64, forKey: .photoBase64)
        try container.encode(gender, forKey: .gender)
        try container.encode(idType, forKey: .idType)
        try container.encode(address, forKey: .address)
        try container.encode(country, forKey: .country)
        try container.encode(documentImageBase64, forKey: .documentImageBase64)
        try container.encode(fullData, forKey: .fullData)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(idNumber, forKey: .idNumber)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(phoneNumber2, forKey: .phoneNumber2)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(secondaryIdNumber, forKey: .secondaryIdNumber)
        try container.encode(idNumberPreviouslyRegistered, forKey: .idNumberPreviouslyRegistered)
        try container.encode(previousRegistrantsUserIds, forKey: .previousRegistrantsUserIds)
        try super.encode(to: encoder)
    }
}

public struct Antifraud: Codable {
    public let suspectUsers: [SuspectUser]?

    enum CodingKeys: String, CodingKey {
        case suspectUsers = "SuspectUsers"
    }
}

public struct SuspectUser: Codable {
    public let userId: String?
    public let reason: String?

    enum CodingKeys: String, CodingKey {
        case reason = "reason"
        case userId = "user_id"
    }
}

public struct Actions: Codable {
    public var documentCheck: ActionResult
    public var humanReviewCompare: ActionResult
    public var humanReviewDocumentCheck: ActionResult
    public var humanReviewLivenessCheck: ActionResult
    public var humanReviewSelfieCheck: ActionResult
    public var humanReviewUpdateSelfie: ActionResult
    public var livenessCheck: ActionResult
    public var selfieCheck: ActionResult
    public var registerSelfie: ActionResult
    public var returnPersonalInfo: ActionResult
    public var selfieProvided: ActionResult
    public var selfieToIdAuthorityCompare: ActionResult
    public var selfieToIdCardCompare: ActionResult
    public var selfieToRegisteredSelfieCompare: ActionResult
    public var updateRegisteredSelfieOnFile: ActionResult
    public var verifyDocument: ActionResult
    public var verifyIdNumber: ActionResult

    enum CodingKeys: String, CodingKey {
        case documentCheck = "Document_Check"
        case humanReviewCompare = "Human_Review_Compare"
        case humanReviewDocumentCheck = "Human_Review_Document_Check"
        case humanReviewLivenessCheck = "Human_Review_Liveness_Check"
        case humanReviewSelfieCheck = "Human_Review_Selfie_Check"
        case humanReviewUpdateSelfie = "Human_Review_Update_Selfie"
        case livenessCheck = "Liveness_Check"
        case selfieCheck = "Selfie_Check"
        case registerSelfie = "Register_Selfie"
        case returnPersonalInfo = "Return_Personal_Info"
        case selfieProvided = "Selfie_Provided"
        case selfieToIdAuthorityCompare = "Selfie_To_ID_Authority_Compare"
        case selfieToIdCardCompare = "Selfie_To_ID_Card_Compare"
        case selfieToRegisteredSelfieCompare = "Selfie_To_Registered_Selfie_Compare"
        case updateRegisteredSelfieOnFile = "Update_Registered_Selfie_On_File"
        case verifyDocument = "Verify_Document"
        case verifyIdNumber = "Verify_ID_Number"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .documentCheck
        ) ?? .notApplicable
        humanReviewCompare = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .humanReviewCompare
        ) ?? .notApplicable
        humanReviewDocumentCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .humanReviewDocumentCheck
        ) ?? .notApplicable
        humanReviewLivenessCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .humanReviewLivenessCheck
        ) ?? .notApplicable
        humanReviewSelfieCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .humanReviewSelfieCheck
        ) ?? .notApplicable
        humanReviewUpdateSelfie = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .humanReviewUpdateSelfie
        ) ?? .notApplicable
        livenessCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .livenessCheck
        ) ?? .notApplicable
        selfieCheck = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .selfieCheck
        ) ?? .notApplicable
        registerSelfie = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .registerSelfie
        ) ?? .notApplicable
        returnPersonalInfo = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .returnPersonalInfo
        ) ?? .notApplicable
        selfieProvided = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .selfieProvided
        ) ?? .notApplicable
        selfieToIdAuthorityCompare = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .selfieToIdAuthorityCompare
        ) ?? .notApplicable
        selfieToIdCardCompare = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .selfieToIdCardCompare
        ) ?? .notApplicable
        selfieToRegisteredSelfieCompare = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .selfieToRegisteredSelfieCompare
        ) ?? .notApplicable
        updateRegisteredSelfieOnFile = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .updateRegisteredSelfieOnFile
        ) ?? .notApplicable
        verifyDocument = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .verifyDocument
        ) ?? .notApplicable
        verifyIdNumber = try container.decodeIfPresent(
            ActionResult.self,
            forKey: .verifyIdNumber
        ) ?? .notApplicable
    }

    init(
        documentCheck: ActionResult = ActionResult.notApplicable,
        humanReviewCompare: ActionResult = ActionResult.notApplicable,
        humanReviewDocumentCheck: ActionResult = ActionResult.notApplicable,
        humanReviewLivenessCheck: ActionResult = ActionResult.notApplicable,
        humanReviewSelfieCheck: ActionResult = ActionResult.notApplicable,
        humanReviewUpdateSelfie: ActionResult = ActionResult.notApplicable,
        livenessCheck: ActionResult = ActionResult.notApplicable,
        selfieCheck: ActionResult = ActionResult.notApplicable,
        registerSelfie: ActionResult = ActionResult.notApplicable,
        returnPersonalInfo: ActionResult = ActionResult.notApplicable,
        selfieProvided: ActionResult = ActionResult.notApplicable,
        selfieToIdAuthorityCompare: ActionResult = ActionResult.notApplicable,
        selfieToIdCardCompare: ActionResult = ActionResult.notApplicable,
        selfieToRegisteredSelfieCompare: ActionResult = ActionResult.notApplicable,
        updateRegisteredSelfieOnFile: ActionResult = ActionResult.notApplicable,
        verifyDocument: ActionResult = ActionResult.notApplicable,
        verifyIdNumber: ActionResult = ActionResult.notApplicable
    ) {
        self.documentCheck = documentCheck
        self.humanReviewCompare = humanReviewCompare
        self.humanReviewDocumentCheck = humanReviewDocumentCheck
        self.humanReviewLivenessCheck = humanReviewLivenessCheck
        self.humanReviewSelfieCheck = humanReviewSelfieCheck
        self.humanReviewUpdateSelfie = humanReviewUpdateSelfie
        self.livenessCheck = livenessCheck
        self.selfieCheck = selfieCheck
        self.registerSelfie = registerSelfie
        self.returnPersonalInfo = returnPersonalInfo
        self.selfieProvided = selfieProvided
        self.selfieToIdAuthorityCompare = selfieToIdAuthorityCompare
        self.selfieToIdCardCompare = selfieToIdCardCompare
        self.selfieToRegisteredSelfieCompare = selfieToRegisteredSelfieCompare
        self.updateRegisteredSelfieOnFile = updateRegisteredSelfieOnFile
        self.verifyDocument = verifyDocument
        self.verifyIdNumber = verifyIdNumber
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
    case idAuthorityPhotoNotAvailable = "ID Authority Photo Not Available"
    case sentToHumanReview = "Sent to Human Review"
    /// This case is used to handle any ActionResult value that does not match the defined enum cases.
    /// It prevents the decoding process from failing when encountering unexpected values.
    case unknown

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ActionResult(rawValue: rawValue) ?? .unknown
    }
}

public struct ImageLinks: Codable {
    public var selfieImageUrl: String?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case selfieImageUrl = "selfie_image"
        case error
    }
}

public struct FlexibleDictionary: Codable {
    enum Value: Codable {
        case string(String)
        case bool(Bool)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            }
        }
    }

    var dictionary: [String: Value]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.dictionary = try container.decode([String: Value].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dictionary)
    }
}
