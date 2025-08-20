import SwiftUI

struct ActiveProduct: Identifiable {
  let id = UUID()
  let product: BusinessProduct
}

@MainActor
final class VerificationDemoViewModel: ObservableObject {
  @Published var activeProduct: ActiveProduct?

  func startSelfieEnrolment() {
    let product =
      VerificationProductBuilder
        .selfieEnrolment()
        .hidePreview()
        .withExtraParams(["userId": "demo_user_123", "sessionId": "session_456"])
        .build()

    activeProduct = ActiveProduct(product: product)
  }

  func startDocumentVerification() {
    let product =
      VerificationProductBuilder
        .documentVerification()
        .captureOneSide()
        .withAutoCapture()
        .withLivenessType(.headPose)
        .withDocumentInfo(["documentType": "passport", "country": "NG"])
        .withExtraParams(["partnerId": "partner_789"])
        .build()

    activeProduct = ActiveProduct(product: product)
  }

  func startBiometricKYC() {
    let product =
      VerificationProductBuilder
        .biometricKYC()
        .withDocumentInfo(["idNumber": "A12345678", "idType": "national_id"])
        .withConsentInfo(["dataProcessing": "granted", "timestamp": "2024-01-15T10:30:00Z"])
        .withLivenessType(.smileDetection)
        .withExtraParams(["kycLevel": "enhanced", "region": "africa"])
        .build()

    activeProduct = ActiveProduct(product: product)
  }
}

