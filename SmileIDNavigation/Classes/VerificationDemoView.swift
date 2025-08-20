import SwiftUI

struct VerificationDemoView: View {
  @Backport.StateObject private var viewModel = VerificationDemoViewModel()

  var body: some View {
    VStack(spacing: 30) {
      Text("Verification Products Demo")
        .font(.title)
        .fontWeight(.bold)
        .padding(.top)

      VStack(spacing: 20) {
        Button(action: {
          viewModel.startSelfieEnrolment()
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
          viewModel.startDocumentVerification()
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
          viewModel.startBiometricKYC()
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
    .sheet(item: $viewModel.activeProduct, onDismiss: {
      viewModel.activeProduct = nil
    }) { active in
      VerificationFlowView(
        product: active.product,
        onEvent: { event in
          print("Verification event: \(event)")
        },
        onCompletion: { _ in
          self.viewModel.activeProduct = nil
        }
      )
    }
  }
}

#if DEBUG
  #Preview {
    VerificationDemoView()
  }
#endif
