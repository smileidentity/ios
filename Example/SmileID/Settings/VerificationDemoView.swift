import SmileIDNavigation
import SwiftUI

private struct ActiveProduct: Identifiable {
  let id = UUID()
  let product: BusinessProduct
}

struct VerificationDemoView: View {
  @State private var activeProduct: ActiveProduct?

  var body: some View {
    VStack(spacing: 30) {
      Text("v12 Verification Products")
        .font(.title)
        .fontWeight(.bold)
        .padding(.top)

      VStack(spacing: 20) {
        Button(action: {
          startSelfieEnrolment()
        }) {
          Text("Selfie Enrolment")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
        }

        Button(action: {
          startDocumentVerification()
        }) {
          Text("Document Verification")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(10)
        }

        Button(action: {
          startBiometricKYC()
        }) {
          Text("Biometric KYC")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .cornerRadius(10)
        }
      }
      .padding(.horizontal)

      Spacer()
    }
    .padding()
    .fullScreenCover(
      item: $activeProduct,
      onDismiss: {
        activeProduct = nil
      }
    ) { active in
      VerificationFlowView(
        product: active.product,
        onEvent: { event in
          print("Verification event: \(event)")
        },
        onCompletion: { _ in
          self.activeProduct = nil
        }
      )
    }
  }

  private func startSelfieEnrolment() {
    let product =
      VerificationProductBuilder
        .selfieEnrolment()
        .hidePreview()
        .withExtraParams(["userId": "demo_user_123", "sessionId": "session_456"])
        .build()

    activeProduct = ActiveProduct(product: product)
  }

  private func startDocumentVerification() {
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

  private func startBiometricKYC() {
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

#if DEBUG
  #Preview {
    VerificationDemoView()
  }
#endif
