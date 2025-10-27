import Foundation

// MARK: - Validation State

/// Represents the validation state of a flow configuration.
public enum ValidationState {
  case valid
  case invalid([FlowValidationIssue])

  /// Computed property for checking if valid
  public var isValid: Bool {
    if case .valid = self {
      return true
    }
    return false
  }

  /// Computed property for checking if invalid
  public var isInvalid: Bool {
    !isValid
  }

  /// Get all validation issues
  public var issues: [FlowValidationIssue] {
    if case .invalid(let issues) = self {
      return issues
    }
    return []
  }

  /// Get the primary (first) issue if invalid
  public var primaryIssue: FlowValidationIssue? {
    if case .invalid(let issues) = self {
      return issues.first
    }
    return nil
  }
}

// MARK: - Screen Index

/// Inline value structure for screen indices to avoid confusion with other integers.
public struct ScreenIndex: Equatable, Hashable, CustomStringConvertible {
  let value: Int

  init(_ value: Int) {
    self.value = value
  }

  public var description: String {
    "\(value)"
  }
}

// MARK: - Issue Severity

/// Severity levels for validation issues.
public enum IssueSeverity: String {
  case error
  case warning

  public var symbol: String {
    switch self {
    case .error: return "❌"
    case .warning: return "⚠️"
    }
  }

  public var displayName: String {
    rawValue.capitalized
  }
}

// MARK: - Flow Validation Issue Protocol

/// Sealed hierarchy for detailed validation issues enabling exhaustive handling.
public protocol FlowValidationIssue {
  var severity: IssueSeverity { get }
  var message: String { get }
  var suggestedFix: String? { get }
}

// MARK: - No Screens Defined Issue

public struct NoScreensDefinedIssue: FlowValidationIssue {
  public let severity: IssueSeverity
  public let message: String
  public let suggestedFix: String?

  init(severity: IssueSeverity = .error) {
    self.severity = severity
    self.message = "No screens have been configured in the flow"
    self.suggestedFix = "Add at least one screen using: screens { screen { ... } }"
  }
}

// MARK: - Empty Screens Block Issue

public struct EmptyScreensBlockIssue: FlowValidationIssue {
  public let severity: IssueSeverity
  public let message: String
  public let suggestedFix: String?

  init(severity: IssueSeverity = .error) {
    self.severity = severity
    self.message = "screens { } block is empty - no screens were added"
    self.suggestedFix = "Add screens using the builder: screen { " +
      "instructions { ... } | capture { ... } | preview { ... } }"
  }
}

// MARK: - Duplicate Screen Type Issue

public struct DuplicateScreenTypeIssue: FlowValidationIssue {
  public let screenType: ScreenType
  public let indices: [ScreenIndex]
  public let severity: IssueSeverity

  init(
    screenType: ScreenType,
    indices: [ScreenIndex],
    severity: IssueSeverity = .error
  ) {
    self.screenType = screenType
    self.indices = indices
    self.severity = severity
  }

  public var message: String {
    let indicesString = indices.map(\.description).joined(separator: ", ")
    return "Duplicate screen type '\(screenType)' found at indices: \(indicesString)"
  }

  public var suggestedFix: String? {
    "Each screen must be unique. Remove the duplicates or change their types."
  }
}

// MARK: - Invalid Screen Order Issue

public struct InvalidScreenOrderIssue: FlowValidationIssue {
  public let detail: String
  public let severity: IssueSeverity

  init(
    description detail: String,
    severity: IssueSeverity = .warning
  ) {
    self.detail = detail
    self.severity = severity
  }

  public var message: String {
    "Screen order issue: \(detail)"
  }

  public var suggestedFix: String? {
    "Recommended order: Instructions → Capture → Preview"
  }
}

// MARK: - Invalid Selfie Capture Config Issue

public struct InvalidSelfieCaptureConfigIssue: FlowValidationIssue {
  public let detail: String
  public let severity: IssueSeverity

  init(
    detail: String,
    severity: IssueSeverity = .error
  ) {
    self.detail = detail
    self.severity = severity
  }

  public var message: String {
    "Invalid selfie capture configuration: \(detail)"
  }

  public var suggestedFix: String? {
    "Ensure enableLiveness and numLivenessImages are properly configured."
  }
}

// MARK: - Invalid Document Capture Config Issue

public struct InvalidDocumentCaptureConfigIssue: FlowValidationIssue {
  public let detail: String
  public let severity: IssueSeverity

  init(
    detail: String,
    severity: IssueSeverity = .error
  ) {
    self.detail = detail
    self.severity = severity
  }

  public var message: String {
    "Invalid document capture configuration: \(detail)"
  }

  public var suggestedFix: String? {
    "Ensure document-specific properties are valid."
  }
}

// MARK: - Equatable Conformance

extension ValidationState: Equatable {
  public static func == (lhs: ValidationState, rhs: ValidationState) -> Bool {
    switch (lhs, rhs) {
    case (.valid, .valid):
      return true
    case (.invalid(let lhsIssues), .invalid(let rhsIssues)):
      return lhsIssues.map(\.message) == rhsIssues.map(\.message)
    default:
      return false
    }
  }
}

extension NoScreensDefinedIssue: Equatable {
  public static func == (lhs: NoScreensDefinedIssue, rhs: NoScreensDefinedIssue) -> Bool {
    lhs.severity == rhs.severity &&
      lhs.message == rhs.message
  }
}

extension EmptyScreensBlockIssue: Equatable {
  public static func == (lhs: EmptyScreensBlockIssue, rhs: EmptyScreensBlockIssue) -> Bool {
    lhs.severity == rhs.severity &&
      lhs.message == rhs.message
  }
}

extension DuplicateScreenTypeIssue: Equatable {
  public static func == (lhs: DuplicateScreenTypeIssue, rhs: DuplicateScreenTypeIssue) -> Bool {
    lhs.screenType == rhs.screenType &&
      lhs.indices == rhs.indices &&
      lhs.severity == rhs.severity
  }
}

extension InvalidScreenOrderIssue: Equatable {
  public static func == (lhs: InvalidScreenOrderIssue, rhs: InvalidScreenOrderIssue) -> Bool {
    lhs.detail == rhs.detail &&
      lhs.severity == rhs.severity
  }
}

extension InvalidSelfieCaptureConfigIssue: Equatable {
  public static func == (lhs: InvalidSelfieCaptureConfigIssue, rhs: InvalidSelfieCaptureConfigIssue) -> Bool {
    lhs.detail == rhs.detail &&
      lhs.severity == rhs.severity
  }
}

extension InvalidDocumentCaptureConfigIssue: Equatable {
  public static func == (lhs: InvalidDocumentCaptureConfigIssue, rhs: InvalidDocumentCaptureConfigIssue) -> Bool {
    lhs.detail == rhs.detail &&
      lhs.severity == rhs.severity
  }
}

// MARK: - Hashable Conformance

extension NoScreensDefinedIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(severity)
    hasher.combine(message)
  }
}

extension EmptyScreensBlockIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(severity)
    hasher.combine(message)
  }
}

extension DuplicateScreenTypeIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(screenType)
    hasher.combine(indices)
    hasher.combine(severity)
  }
}

extension InvalidScreenOrderIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(detail)
    hasher.combine(severity)
  }
}

extension InvalidSelfieCaptureConfigIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(detail)
    hasher.combine(severity)
  }
}

extension InvalidDocumentCaptureConfigIssue: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(detail)
    hasher.combine(severity)
  }
}

// MARK: - Convenience Extensions

extension ValidationState {
  /// Get all error-level issues
  var errors: [FlowValidationIssue] {
    issues.filter { $0.severity == .error }
  }

  /// Get all warning-level issues
  var warnings: [FlowValidationIssue] {
    issues.filter { $0.severity == .warning }
  }

  /// Check if there are any errors
  var hasErrors: Bool {
    !errors.isEmpty
  }

  /// Check if there are any warnings
  var hasWarnings: Bool {
    !warnings.isEmpty
  }

  /// Get a formatted description of all issues
  var formattedDescription: String {
    guard case .invalid(let issues) = self else {
      return "Valid"
    }

    var result = ""
    for (index, issue) in issues.enumerated() {
      result += "\(index + 1). \(issue.severity.symbol) \(issue.message)\n"
      if let fix = issue.suggestedFix {
        result += "   💡 Fix: \(fix)\n"
      }
    }
    return result
  }
}

extension ScreenIndex: Comparable {
  public static func < (lhs: ScreenIndex, rhs: ScreenIndex) -> Bool {
    lhs.value < rhs.value
  }
}

extension IssueSeverity: Comparable {
  public static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
    switch (lhs, rhs) {
    case (.warning, .error):
      return true
    default:
      return false
    }
  }
}

// MARK: - Type-safe issue handling

extension [FlowValidationIssue] {
  /// Filter issues by type
  func issues<T: FlowValidationIssue>(ofType _: T.Type) -> [T] {
    compactMap { $0 as? T }
  }

  /// Get all no screens defined issues
  var noScreensIssues: [NoScreensDefinedIssue] {
    issues(ofType: NoScreensDefinedIssue.self)
  }

  /// Get all empty screens block issues
  var emptyScreensIssues: [EmptyScreensBlockIssue] {
    issues(ofType: EmptyScreensBlockIssue.self)
  }

  /// Get all duplicate screen type issues
  var duplicateScreenIssues: [DuplicateScreenTypeIssue] {
    issues(ofType: DuplicateScreenTypeIssue.self)
  }

  /// Get all invalid screen order issues
  var screenOrderIssues: [InvalidScreenOrderIssue] {
    issues(ofType: InvalidScreenOrderIssue.self)
  }

  /// Get all invalid selfie capture config issues
  var selfieCaptureIssues: [InvalidSelfieCaptureConfigIssue] {
    issues(ofType: InvalidSelfieCaptureConfigIssue.self)
  }

  /// Get all invalid document capture config issues
  var documentCaptureIssues: [InvalidDocumentCaptureConfigIssue] {
    issues(ofType: InvalidDocumentCaptureConfigIssue.self)
  }
}
