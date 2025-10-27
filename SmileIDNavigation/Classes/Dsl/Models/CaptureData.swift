import Foundation

// MARK: - Flow Result

/// Result of a SmileID flow execution
public enum FlowResult {
  /// Flow completed successfully with captured data
  case success(CapturedFlowData)

  /// Flow failed with an error
  case failure(Error)
}

// MARK: - Validation Exception

public struct ValidationException: Error, LocalizedError {
  let message: String
  let validationState: ValidationState

  init(message: String, validationState: ValidationState) {
    self.message = message
    self.validationState = validationState
  }

  /// Get a formatted error message with all validation errors
  public var errorDescription: String? {
    var result = message
    result += "\nValidation errors:\n"

    for (index, issue) in validationState.issues.enumerated() {
      result += "  \(index + 1). \(issue.message)"
      if let fix = issue.suggestedFix {
        result += "\n     Fix: \(fix)"
      }
      result += "\n"
    }

    return result
  }

  public var localizedDescription: String {
    errorDescription ?? message
  }
}

// MARK: - Captured Flow Data

/// All data captured during the flow
public struct CapturedFlowData {
  let screens: [ScreenType: ScreenCaptureResult]
  let metadata: CaptureMetadata
  let integrityHash: String
  let captureTimestamp: Int64
  let sdkVersion: String

  init(
    screens: [ScreenType: ScreenCaptureResult],
    metadata: CaptureMetadata,
    integrityHash: String,
    captureTimestamp: Int64,
    sdkVersion: String
  ) {
    self.screens = screens
    self.metadata = metadata
    self.integrityHash = integrityHash
    self.captureTimestamp = captureTimestamp
    self.sdkVersion = sdkVersion
  }
}

// MARK: - Screen Capture Result

/// Result from a specific screen
public enum ScreenCaptureResult {
  /// User consent captured
  case consent(granted: Bool, timestamp: Int64)

  /// Selfie image captured
  case selfieCapture(
    imageUri: String,
    livenessImages: [String],
    qualityScore: Float
  )

  /// Document images captured
  case documentCapture(
    frontImageUri: String,
    backImageUri: String?,
    documentType: String?,
    qualityScore: Float
  )
}

// MARK: - Capture Metadata

/// Metadata about the capture session
public struct CaptureMetadata {
  let deviceModel: String
  let osVersion: String
  let screenDensity: Float
  let locale: String
  let captureMode: String
  let flashUsed: Bool

  init(
    deviceModel: String,
    osVersion: String,
    screenDensity: Float,
    locale: String,
    captureMode: String,
    flashUsed: Bool = false
  ) {
    self.deviceModel = deviceModel
    self.osVersion = osVersion
    self.screenDensity = screenDensity
    self.locale = locale
    self.captureMode = captureMode
    self.flashUsed = flashUsed
  }
}

// MARK: - Equatable Conformance

extension FlowResult: Equatable {
  public static func == (lhs: FlowResult, rhs: FlowResult) -> Bool {
    switch (lhs, rhs) {
    case (.success(let lhsData), .success(let rhsData)):
      return lhsData == rhsData
    case (.failure(let lhsError), .failure(let rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}

extension ValidationException: Equatable {
  public static func == (lhs: ValidationException, rhs: ValidationException) -> Bool {
    lhs.message == rhs.message &&
      lhs.validationState == rhs.validationState
  }
}

extension CapturedFlowData: Equatable {
  public static func == (lhs: CapturedFlowData, rhs: CapturedFlowData) -> Bool {
    lhs.screens == rhs.screens &&
      lhs.metadata == rhs.metadata &&
      lhs.integrityHash == rhs.integrityHash &&
      lhs.captureTimestamp == rhs.captureTimestamp &&
      lhs.sdkVersion == rhs.sdkVersion
  }
}

extension ScreenCaptureResult: Equatable {
  public static func == (lhs: ScreenCaptureResult, rhs: ScreenCaptureResult) -> Bool {
    switch (lhs, rhs) {
    case (.consent(let lGranted, let lTimestamp), .consent(let rGranted, let rTimestamp)):
      return lGranted == rGranted && lTimestamp == rTimestamp

    case (.selfieCapture(let lUri, let lLiveness, let lQuality),
          .selfieCapture(let rUri, let rLiveness, let rQuality)):
      return lUri == rUri && lLiveness == rLiveness && lQuality == rQuality

    case (.documentCapture(let lFront, let lBack, let lType, let lQuality),
          .documentCapture(let rFront, let rBack, let rType, let rQuality)):
      return lFront == rFront && lBack == rBack && lType == rType && lQuality == rQuality

    default:
      return false
    }
  }
}

extension CaptureMetadata: Equatable {
  public static func == (lhs: CaptureMetadata, rhs: CaptureMetadata) -> Bool {
    lhs.deviceModel == rhs.deviceModel &&
      lhs.osVersion == rhs.osVersion &&
      lhs.screenDensity == rhs.screenDensity &&
      lhs.locale == rhs.locale &&
      lhs.captureMode == rhs.captureMode &&
      lhs.flashUsed == rhs.flashUsed
  }
}

// MARK: - Hashable Conformance

extension CapturedFlowData: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(integrityHash)
    hasher.combine(captureTimestamp)
    hasher.combine(sdkVersion)
  }
}

extension ScreenCaptureResult: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .consent(let granted, let timestamp):
      hasher.combine(granted)
      hasher.combine(timestamp)
    case .selfieCapture(let uri, let liveness, let quality):
      hasher.combine(uri)
      hasher.combine(liveness)
      hasher.combine(quality)
    case .documentCapture(let front, let back, let type, let quality):
      hasher.combine(front)
      hasher.combine(back)
      hasher.combine(type)
      hasher.combine(quality)
    }
  }
}

extension CaptureMetadata: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(deviceModel)
    hasher.combine(osVersion)
    hasher.combine(screenDensity)
    hasher.combine(locale)
    hasher.combine(captureMode)
    hasher.combine(flashUsed)
  }
}

// MARK: - Convenience Extensions

extension ScreenCaptureResult {
  /// Check if this is a consent result
  var isConsent: Bool {
    if case .consent = self { return true }
    return false
  }

  /// Check if this is a selfie capture result
  var isSelfie: Bool {
    if case .selfieCapture = self { return true }
    return false
  }

  /// Check if this is a document capture result
  var isDocument: Bool {
    if case .documentCapture = self { return true }
    return false
  }

  /// Extract consent value if this is a consent result
  var consentGranted: Bool? {
    if case .consent(let granted, _) = self {
      return granted
    }
    return nil
  }

  /// Extract selfie URI if this is a selfie result
  var selfieUri: String? {
    if case .selfieCapture(let uri, _, _) = self {
      return uri
    }
    return nil
  }

  /// Extract document front URI if this is a document result
  var documentFrontUri: String? {
    if case .documentCapture(let front, _, _, _) = self {
      return front
    }
    return nil
  }
}

extension CapturedFlowData {
  /// Get consent result if available
  var consentResult: ScreenCaptureResult? {
    screens.values.first { $0.isConsent }
  }

  /// Get selfie result if available
  var selfieResult: ScreenCaptureResult? {
    screens.values.first { $0.isSelfie }
  }

  /// Get document result if available
  var documentResult: ScreenCaptureResult? {
    screens.values.first { $0.isDocument }
  }

  /// Check if user granted consent
  var hasConsent: Bool {
    consentResult?.consentGranted == true
  }
}
