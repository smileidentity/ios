import Foundation
import SmileID

struct JobData: Identifiable {
    var id: String {
        return jobId
    }
    var jobType: JobType
    var timestamp: Date
    var userId: String
    var jobId: String
    var jobComplete: Bool = false
    var jobSuccess: Bool = false
    var code: String?
    var resultCode: String?
    var smileJobId: String?
    var resultText: String?
    var selfieImageUrl: String?
}

extension JobType {
    var label: String {
        switch self {
        case .biometricKyc:
            return "Biometric KYC"
        case .smartSelfieAuthentication:
            return "SmartSelfie™ Authentication"
        case .smartSelfieEnrollment:
            return "SmartSelfie™ Enrollment"
        case .enhancedKyc:
            return "Enhanced KYC"
        case .documentVerification:
            return "Document Verification"
        case .bvn:
            return "BVN Consent"
        case .enhancedDocumentVerification:
            return "Enhanced Document Verification"
        }
    }
    var icon: String {
        switch self {
        case .biometricKyc:
            return "biometric"
        case .smartSelfieAuthentication:
            return "smart_selfie_authentication"
        case .smartSelfieEnrollment:
            return "smart_selfie_enroll"
        case .enhancedKyc:
            return "enhanced_kyc"
        case .documentVerification:
            return "document"
        case .bvn:
            return "biometric"
        case .enhancedDocumentVerification:
            return "enhanced_doc_v"
        }
    }
}

extension JobData {
    init?(managedObject: Job) {
        guard let jobType = JobType(rawValue: Int(managedObject.jobType)) else {
            return nil
        }
        self.init(
            jobType: jobType,
            timestamp: managedObject.timestamp,
            userId: managedObject.userId,
            jobId: managedObject.jobId,
            jobComplete: managedObject.jobComplete,
            jobSuccess: managedObject.jobSuccess,
            code: managedObject.code,
            resultCode: managedObject.resultCode,
            smileJobId: managedObject.smileJobId,
            resultText: managedObject.resultText,
            selfieImageUrl: managedObject.selfieImageUrl
        )
    }
}

#if DEBUG
extension JobData {
    static var documentVerification: JobData {
        return .init(
            jobType: .documentVerification,
            timestamp: Date(),
            userId: "6a811664-ba17-460a-b8c6-54b8f8dda0c0_742418bf-d7dd-450b-9785-420d3773496a",
            jobId: "742418bf-d7dd-450b-9785-420d3773496a",
            jobComplete: false,
            jobSuccess: false,
            code: "2340",
            resultCode: "8822",
            smileJobId: "420d3773496a-d7dd-450b-9785-742418bf",
            resultText: "Document Verified"
        )
    }
}
#endif
