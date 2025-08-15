import SwiftUI

protocol VerificationProductConfig: Sendable, Equatable {
  func generateRoute() -> [NavigationDestination]
}

public struct SelfieEnrolmentConfig: VerificationProductConfig {
  let showInstructions: Bool
  let showPreview: Bool
  let extraParams: [String: String]

  public init(
    showInstructions: Bool = true,
    showPreview: Bool = true,
    extraParams: [String: String] = [:]
  ) {
    self.showInstructions = showInstructions
    self.showPreview = showPreview
    self.extraParams = extraParams
  }

  func generateRoute() -> [NavigationDestination] {
    var steps: [NavigationDestination] = []

    if showInstructions {
      steps.append(.instructions)
    }

    steps.append(.capture(.selfie))

    if showPreview {
      steps.append(.preview(.selfie))
    }

    steps.append(.processing)
    steps.append(.done)

    return steps
  }
}

public struct DocumentVerificationConfig: VerificationProductConfig {
  let showInstructions: Bool
  let showPreview: Bool
  let captureBothSides: Bool
  let captureMode: CaptureMode
  let livenessType: LivenessType
  let documentInfo: [String: String]?
  let extraParams: [String: String]

  public init(
    showInstructions: Bool = true,
    showPreview: Bool = true,
    captureBothSides: Bool = true,
    captureMode: CaptureMode = .manual,
    livenessType: LivenessType = .smileDetection,
    documentInfo: [String: String]? = nil,
    extraParams: [String: String] = [:]
  ) {
    self.showInstructions = showInstructions
    self.showPreview = showPreview
    self.captureBothSides = captureBothSides
    self.captureMode = captureMode
    self.livenessType = livenessType
    self.documentInfo = documentInfo
    self.extraParams = extraParams
  }

  func generateRoute() -> [NavigationDestination] {
    var steps: [NavigationDestination] = []

    if showInstructions {
      steps.append(.instructions)
    }

    if documentInfo != nil {
      steps.append(.documentInfo)
    }

    steps.append(.capture(.documentFront))
    if showPreview {
      steps.append(.preview(.documentFront))
    }

    if captureBothSides {
      steps.append(.capture(.documentBack))
      if showPreview {
        steps.append(.preview(.documentBack))
      }
    }

    steps.append(.capture(.selfie))
    if showPreview {
      steps.append(.preview(.selfie))
    }

    steps.append(.processing)
    steps.append(.done)

    return steps
  }
}

public struct BiometricKYCConfig: VerificationProductConfig {
  let showInstructions: Bool
  let documentInfo: [String: String]?
  let consentInfo: [String: String]?
  let livenessType: LivenessType
  let extraParams: [String: String]

  public init(
    showInstructions: Bool = true,
    documentInfo: [String: String]? = nil,
    consentInfo: [String: String]? = nil,
    livenessType: LivenessType = .smileDetection,
    extraParams: [String: String] = [:]
  ) {
    self.showInstructions = showInstructions
    self.documentInfo = documentInfo
    self.consentInfo = consentInfo
    self.livenessType = livenessType
    self.extraParams = extraParams
  }

  func generateRoute() -> [NavigationDestination] {
    var steps: [NavigationDestination] = []

    if showInstructions {
      steps.append(.instructions)
    }

    steps.append(.capture(.selfie))
    steps.append(.preview(.selfie))
    steps.append(.processing)
    steps.append(.done)

    return steps
  }
}
