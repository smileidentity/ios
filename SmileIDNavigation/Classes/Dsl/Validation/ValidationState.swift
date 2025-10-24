import Foundation

// MARK: - Validation State

/// Represents the validation state of a flow configuration.
enum ValidationState {
    case valid
    case invalid([FlowValidationIssue])
    
    /// Computed property for checking if valid
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    /// Computed property for checking if invalid
    var isInvalid: Bool {
        return !isValid
    }
    
    /// Get all validation issues
    var issues: [FlowValidationIssue] {
        if case .invalid(let issues) = self {
            return issues
        }
        return []
    }
    
    /// Get the primary (first) issue if invalid
    var primaryIssue: FlowValidationIssue? {
        if case .invalid(let issues) = self {
            return issues.first
        }
        return nil
    }
}

// MARK: - Screen Index

/// Inline value structure for screen indices to avoid confusion with other integers.
struct ScreenIndex: Equatable, Hashable, CustomStringConvertible {
    let value: Int
    
    init(_ value: Int) {
        self.value = value
    }
    
    var description: String {
        return "\(value)"
    }
}

// MARK: - Issue Severity

/// Severity levels for validation issues.
enum IssueSeverity: String {
    case error
    case warning
    
    var symbol: String {
        switch self {
        case .error: return "❌"
        case .warning: return "⚠️"
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Flow Validation Issue Protocol

/// Sealed hierarchy for detailed validation issues enabling exhaustive handling.
protocol FlowValidationIssue {
    var severity: IssueSeverity { get }
    var message: String { get }
    var suggestedFix: String? { get }
}

// MARK: - No Screens Defined Issue

struct NoScreensDefinedIssue: FlowValidationIssue {
    let severity: IssueSeverity
    let message: String
    let suggestedFix: String?
    
    init(severity: IssueSeverity = .error) {
        self.severity = severity
        self.message = "No screens have been configured in the flow"
        self.suggestedFix = "Add at least one screen using: screens { screen { ... } }"
    }
}

// MARK: - Empty Screens Block Issue

struct EmptyScreensBlockIssue: FlowValidationIssue {
    let severity: IssueSeverity
    let message: String
    let suggestedFix: String?
    
    init(severity: IssueSeverity = .error) {
        self.severity = severity
        self.message = "screens { } block is empty - no screens were added"
        self.suggestedFix = "Add screens using the builder: screen { instructions { ... } | capture { ... } | preview { ... } }"
    }
}

// MARK: - Duplicate Screen Type Issue

struct DuplicateScreenTypeIssue: FlowValidationIssue {
    let screenType: ScreenType
    let indices: [ScreenIndex]
    let severity: IssueSeverity
    
    init(
        screenType: ScreenType,
        indices: [ScreenIndex],
        severity: IssueSeverity = .error
    ) {
        self.screenType = screenType
        self.indices = indices
        self.severity = severity
    }
    
    var message: String {
        let indicesString = indices.map { $0.description }.joined(separator: ", ")
        return "Duplicate screen type '\(screenType)' found at indices: \(indicesString)"
    }
    
    var suggestedFix: String? {
        return "Each screen must be unique. Remove the duplicates or change their types."
    }
}

// MARK: - Invalid Screen Order Issue

struct InvalidScreenOrderIssue: FlowValidationIssue {
    let detail: String
    let severity: IssueSeverity
    
    init(
        description detail: String,
        severity: IssueSeverity = .warning
    ) {
        self.detail = detail
        self.severity = severity
    }
    
    var message: String {
        return "Screen order issue: \(detail)"
    }
    
    var suggestedFix: String? {
        return "Recommended order: Instructions → Capture → Preview"
    }
}

// MARK: - Invalid Selfie Capture Config Issue

struct InvalidSelfieCaptureConfigIssue: FlowValidationIssue {
    let detail: String
    let severity: IssueSeverity
    
    init(
        detail: String,
        severity: IssueSeverity = .error
    ) {
        self.detail = detail
        self.severity = severity
    }
    
    var message: String {
        return "Invalid selfie capture configuration: \(detail)"
    }
    
    var suggestedFix: String? {
        return "Ensure enableLiveness and numLivenessImages are properly configured."
    }
}

// MARK: - Invalid Document Capture Config Issue

struct InvalidDocumentCaptureConfigIssue: FlowValidationIssue {
    let detail: String
    let severity: IssueSeverity
    
    init(
        detail: String,
        severity: IssueSeverity = .error
    ) {
        self.detail = detail
        self.severity = severity
    }
    
    var message: String {
        return "Invalid document capture configuration: \(detail)"
    }
    
    var suggestedFix: String? {
        return "Ensure document-specific properties are valid."
    }
}

// MARK: - Equatable Conformance

extension ValidationState: Equatable {
    static func == (lhs: ValidationState, rhs: ValidationState) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case (.invalid(let lhsIssues), .invalid(let rhsIssues)):
            return lhsIssues.map { $0.message } == rhsIssues.map { $0.message }
        default:
            return false
        }
    }
}

extension NoScreensDefinedIssue: Equatable {
    static func == (lhs: NoScreensDefinedIssue, rhs: NoScreensDefinedIssue) -> Bool {
        return lhs.severity == rhs.severity &&
               lhs.message == rhs.message
    }
}

extension EmptyScreensBlockIssue: Equatable {
    static func == (lhs: EmptyScreensBlockIssue, rhs: EmptyScreensBlockIssue) -> Bool {
        return lhs.severity == rhs.severity &&
               lhs.message == rhs.message
    }
}

extension DuplicateScreenTypeIssue: Equatable {
    static func == (lhs: DuplicateScreenTypeIssue, rhs: DuplicateScreenTypeIssue) -> Bool {
        return lhs.screenType == rhs.screenType &&
               lhs.indices == rhs.indices &&
               lhs.severity == rhs.severity
    }
}

extension InvalidScreenOrderIssue: Equatable {
    static func == (lhs: InvalidScreenOrderIssue, rhs: InvalidScreenOrderIssue) -> Bool {
        return lhs.detail == rhs.detail &&
               lhs.severity == rhs.severity
    }
}

extension InvalidSelfieCaptureConfigIssue: Equatable {
    static func == (lhs: InvalidSelfieCaptureConfigIssue, rhs: InvalidSelfieCaptureConfigIssue) -> Bool {
        return lhs.detail == rhs.detail &&
               lhs.severity == rhs.severity
    }
}

extension InvalidDocumentCaptureConfigIssue: Equatable {
    static func == (lhs: InvalidDocumentCaptureConfigIssue, rhs: InvalidDocumentCaptureConfigIssue) -> Bool {
        return lhs.detail == rhs.detail &&
               lhs.severity == rhs.severity
    }
}

// MARK: - Hashable Conformance

extension NoScreensDefinedIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(severity)
        hasher.combine(message)
    }
}

extension EmptyScreensBlockIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(severity)
        hasher.combine(message)
    }
}

extension DuplicateScreenTypeIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(screenType)
        hasher.combine(indices)
        hasher.combine(severity)
    }
}

extension InvalidScreenOrderIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(detail)
        hasher.combine(severity)
    }
}

extension InvalidSelfieCaptureConfigIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(detail)
        hasher.combine(severity)
    }
}

extension InvalidDocumentCaptureConfigIssue: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(detail)
        hasher.combine(severity)
    }
}

// MARK: - Convenience Extensions

extension ValidationState {
    /// Get all error-level issues
    var errors: [FlowValidationIssue] {
        return issues.filter { $0.severity == .error }
    }
    
    /// Get all warning-level issues
    var warnings: [FlowValidationIssue] {
        return issues.filter { $0.severity == .warning }
    }
    
    /// Check if there are any errors
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    /// Check if there are any warnings
    var hasWarnings: Bool {
        return !warnings.isEmpty
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
    static func < (lhs: ScreenIndex, rhs: ScreenIndex) -> Bool {
        return lhs.value < rhs.value
    }
}

extension IssueSeverity: Comparable {
    static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
        switch (lhs, rhs) {
        case (.warning, .error):
            return true
        default:
            return false
        }
    }
}

// MARK: - Type-safe issue handling

extension Array where Element == FlowValidationIssue {
    /// Filter issues by type
    func issues<T: FlowValidationIssue>(ofType type: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }
    
    /// Get all no screens defined issues
    var noScreensIssues: [NoScreensDefinedIssue] {
        return issues(ofType: NoScreensDefinedIssue.self)
    }
    
    /// Get all empty screens block issues
    var emptyScreensIssues: [EmptyScreensBlockIssue] {
        return issues(ofType: EmptyScreensBlockIssue.self)
    }
    
    /// Get all duplicate screen type issues
    var duplicateScreenIssues: [DuplicateScreenTypeIssue] {
        return issues(ofType: DuplicateScreenTypeIssue.self)
    }
    
    /// Get all invalid screen order issues
    var screenOrderIssues: [InvalidScreenOrderIssue] {
        return issues(ofType: InvalidScreenOrderIssue.self)
    }
    
    /// Get all invalid selfie capture config issues
    var selfieCaptureIssues: [InvalidSelfieCaptureConfigIssue] {
        return issues(ofType: InvalidSelfieCaptureConfigIssue.self)
    }
    
    /// Get all invalid document capture config issues
    var documentCaptureIssues: [InvalidDocumentCaptureConfigIssue] {
        return issues(ofType: InvalidDocumentCaptureConfigIssue.self)
    }
}
