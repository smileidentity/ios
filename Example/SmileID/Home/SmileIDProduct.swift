import Foundation

enum SmileIDProduct: CaseIterable {
    case smartSelfieEnrollment
    case smartSelfieAuthentication
    case enhancedSmartSelfieEnrollment
    case enhancedSmartSelfieAuthentication
    case enhancedKYC
    case biometricKYC
    case documentVerification
    case enhancedDocumentVerification
    
    var image: String {
        switch self {
        case .smartSelfieEnrollment:
            return "smart_selfie_enroll"
        case .smartSelfieAuthentication:
            return "smart_selfie_authentication"
        case .enhancedSmartSelfieEnrollment:
            return "smart_selfie_enroll"
        case .enhancedSmartSelfieAuthentication:
            return "smart_selfie_authentication"
        case .enhancedKYC:
            return "enhanced_kyc"
        case .biometricKYC:
            return "biometric"
        case .documentVerification:
            return "document"
        case .enhancedDocumentVerification:
            return "enhanced_doc_v"
        }
    }
    
    var name: String {
        switch self {
        case .smartSelfieEnrollment:
            return "SmartSelfie™ Enrollment"
        case .smartSelfieAuthentication:
            return "SmartSelfie™ Authentication"
        case .enhancedSmartSelfieEnrollment:
            return "SmartSelfie™ Enrollment (Enhanced)"
        case .enhancedSmartSelfieAuthentication:
            return "SmartSelfie™ Authentication (Enhanced)"
        case .enhancedKYC:
            return "Enhanced KYC"
        case .biometricKYC:
            return "Biometric KYC"
        case .documentVerification:
            return "Document Verification"
        case .enhancedDocumentVerification:
            return "Enhanced Document Verification"
        }
    }
}

extension SmileIDProduct: Identifiable {
    var id: SmileIDProduct {
        return self
    }
}
