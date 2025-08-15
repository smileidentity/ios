import SwiftUI

public enum BusinessProduct: Sendable, Equatable {
  case selfieEnrolment(SelfieEnrolmentConfig)
  case documentVerification(DocumentVerificationConfig)
  case biometricKYC(BiometricKYCConfig)

  public func generateRoute(showInstructions: Bool = true) -> [NavigationDestination] {
    switch self {
    case .selfieEnrolment(let config):
      return config.generateRoute(showInstructions: showInstructions)
    case .documentVerification(let config):
      return config.generateRoute(showInstructions: showInstructions)
    case .biometricKYC(let config):
      return config.generateRoute(showInstructions: showInstructions)
    }
  }

  public var extraParams: [String: String] {
    switch self {
    case .selfieEnrolment(let config):
      return config.extraParams
    case .documentVerification(let config):
      return config.extraParams
    case .biometricKYC(let config):
      return config.extraParams
    }
  }

  public var documentInfo: [String: String]? {
    switch self {
    case .selfieEnrolment:
      return nil
    case .documentVerification(let config):
      return config.documentInfo
    case .biometricKYC(let config):
      return config.documentInfo
    }
  }

  public var livenessType: LivenessType? {
    switch self {
    case .selfieEnrolment:
      return nil
    case .documentVerification(let config):
      return config.livenessType
    case .biometricKYC(let config):
      return config.livenessType
    }
  }

  public var captureMode: CaptureMode? {
    switch self {
    case .selfieEnrolment, .biometricKYC:
      return nil
    case .documentVerification(let config):
      return config.captureMode
    }
  }
}
