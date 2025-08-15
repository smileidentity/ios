import SwiftUI

public final class SelfieEnrolmentBuilder {
	private var showPreview: Bool = true
	private var livenessType: LivenessType = .smileDetection
	private var extraParams: [String: String] = [:]

	public func hidePreview() -> SelfieEnrolmentBuilder {
		showPreview = false
		return self
	}
	
//	public func withLivenessType(_ type: LivenessType) -> SelfieEnrolmentBuilder {
//		livenessType = type
//		return self
//	}

	public func withExtraParams(_ params: [String: String]) -> SelfieEnrolmentBuilder {
		extraParams = params
		return self
	}

	public func build() -> BusinessProduct {
		return .selfieEnrolment(
			SelfieEnrolmentConfig(
				showPreview: showPreview,
				extraParams: extraParams
			)
		)
	}
}

public final class DocumentVerificationBuilder {
	private var showPreview: Bool = true
	private var captureBothSides: Bool = true
	private var captureMode: CaptureMode = .manual
	private var livenessType: LivenessType = .smileDetection
	private var documentInfo: [String: String]? = nil
	private var extraParams: [String: String] = [:]

	public func hidePreview() -> DocumentVerificationBuilder {
		showPreview = false
		return self
	}

	public func captureOneSide() -> DocumentVerificationBuilder {
		captureBothSides = false
		return self
	}

	public func withAutoCapture() -> DocumentVerificationBuilder {
		captureMode = .auto
		return self
	}

	public func withLivenessType(_ type: LivenessType) -> DocumentVerificationBuilder {
		livenessType = type
		return self
	}

	public func withDocumentInfo(_ info: [String: String]) -> DocumentVerificationBuilder {
		documentInfo = info
		return self
	}

	public func withExtraParams(_ params: [String: String]) -> DocumentVerificationBuilder {
		extraParams = params
		return self
	}

	public func build() -> BusinessProduct {
		return .documentVerification(
			DocumentVerificationConfig(
				showPreview: showPreview,
				captureBothSides: captureBothSides,
				captureMode: captureMode,
				livenessType: livenessType,
				documentInfo: documentInfo,
				extraParams: extraParams
			)
		)
	}
}

public final class BiometricKYCBuilder {
	private var documentInfo: [String: String]? = nil
	private var consentInfo: [String: String]? = nil
	private var livenessType: LivenessType = .smileDetection
	private var extraParams: [String: String] = [:]

	public func withDocumentInfo(_ info: [String: String]) -> BiometricKYCBuilder {
		documentInfo = info
		return self
	}

	public func withConsentInfo(_ info: [String: String]) -> BiometricKYCBuilder {
		consentInfo = info
		return self
	}

	public func withLivenessType(_ type: LivenessType) -> BiometricKYCBuilder {
		livenessType = type
		return self
	}

	public func withExtraParams(_ params: [String: String]) -> BiometricKYCBuilder {
		extraParams = params
		return self
	}

	public func build() -> BusinessProduct {
		return .biometricKYC(
			BiometricKYCConfig(
				documentInfo: documentInfo,
				consentInfo: consentInfo,
				livenessType: livenessType,
				extraParams: extraParams
			)
		)
	}
}

public final class VerificationProductBuilder {
	public static func selfieEnrolment() -> SelfieEnrolmentBuilder {
		return SelfieEnrolmentBuilder()
	}

	public static func documentVerification() -> DocumentVerificationBuilder {
		return DocumentVerificationBuilder()
	}

	public static func biometricKYC() -> BiometricKYCBuilder {
		return BiometricKYCBuilder()
	}
}
