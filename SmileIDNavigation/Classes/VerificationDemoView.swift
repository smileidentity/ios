import SwiftUI

struct VerificationDemoView: View {
	@State private var selectedProduct: String = ""
	@State private var showingVerification = false

	var body: some View {
		VStack(spacing: 30) {
			Text("Verification Products Demo")
				.font(.title)
				.fontWeight(.bold)
				.padding(.top)

			VStack(spacing: 20) {
				Button(action: {
					startSelfieEnrolment()
				}) {
					VStack {
						Text("Selfie Enrolment")
							.font(.headline)
							.foregroundColor(.white)
						Text("Instructions → Selfie Capture → Preview → Processing")
							.font(.caption)
							.foregroundColor(.white.opacity(0.8))
					}
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.blue)
					.cornerRadius(10)
				}

				Button(action: {
					startDocumentVerification()
				}) {
					VStack {
						Text("Document Verification")
							.font(.headline)
							.foregroundColor(.white)
						Text("Instructions → Doc Front → Preview → Doc Back → Preview → Selfie → Preview → Processing")
							.font(.caption)
							.foregroundColor(.white.opacity(0.8))
					}
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.green)
					.cornerRadius(10)
				}

				Button(action: {
					startBiometricKYC()
				}) {
					VStack {
						Text("Biometric KYC")
							.font(.headline)
							.foregroundColor(.white)
						Text("Instructions → Selfie Capture → Preview → Processing")
							.font(.caption)
							.foregroundColor(.white.opacity(0.8))
					}
					.padding()
					.frame(maxWidth: .infinity)
					.background(Color.orange)
					.cornerRadius(10)
				}
			}
			.padding(.horizontal)

			if !selectedProduct.isEmpty {
				VStack(alignment: .leading, spacing: 10) {
					Text("Selected Configuration:")
						.font(.headline)

					Text(selectedProduct)
						.font(.caption)
						.padding()
						.background(Color.gray.opacity(0.1))
						.cornerRadius(8)
				}
				.padding()
			}

			Spacer()
		}
		.padding()
	}

	private func startSelfieEnrolment() {
		let product =
			VerificationProductBuilder
			.selfieEnrolment()
			.hidePreview()
			.withExtraParams(["userId": "demo_user_123", "sessionId": "session_456"])
			.build()

		selectedProduct = """
			VerificationProductBuilder
			    .selfieEnrolment()
			    .hidePreview()
			    .withExtraParams([
			        "userId": "demo_user_123",
			        "sessionId": "session_456"
			    ])
			    .build()

			Generated Route: \(product.generateRoute().map { "\($0)" }.joined(separator: " → "))
			"""

		// In a real app, you would start the verification flow here
		print("Starting Selfie Enrolment with route: \(product.generateRoute())")
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

		selectedProduct = """
			VerificationProductBuilder
			    .documentVerification()
			    .captureOneSide()
			    .withAutoCapture()
			    .withLivenessType(.headPose)
			    .withDocumentInfo([
			        "documentType": "passport",
			        "country": "NG"
			    ])
			    .withExtraParams(["partnerId": "partner_789"])
			    .build()

			Generated Route: \(product.generateRoute().map { "\($0)" }.joined(separator: " → "))
			"""

		print("Starting Document Verification with route: \(product.generateRoute())")
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

		selectedProduct = """
			VerificationProductBuilder
			    .biometricKYC()
			    .withDocumentInfo([
			        "idNumber": "A12345678",
			        "idType": "national_id"
			    ])
			    .withConsentInfo([
			        "dataProcessing": "granted",
			        "timestamp": "2024-01-15T10:30:00Z"
			    ])
			    .withLivenessType(.smileDetection)
			    .withExtraParams([
			        "kycLevel": "enhanced",
			        "region": "africa"
			    ])
			    .build()

			Generated Route: \(product.generateRoute().map { "\($0)" }.joined(separator: " → "))
			"""

		print("Starting Biometric KYC with route: \(product.generateRoute())")
	}
}

#if DEBUG
#Preview {
	VerificationDemoView()
}
#endif
