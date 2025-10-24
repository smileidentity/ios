import Foundation

// MARK: - Flow Validator (Class-based)

/// Validator for flow configurations that treats validation errors as state, not exceptions.
/// Class-based implementation with singleton pattern.
final class FlowValidator {
    
    // MARK: - Singleton
    
    static let shared = FlowValidator()
    
    private init() {}
    
    // MARK: - Public Validation Methods
    
    /// Validates a complete flow configuration and returns a ValidationState.
    func validate(configuration: FlowConfiguration) -> ValidationState {
        var issues: [FlowValidationIssue] = []
        
        if configuration.steps.isEmpty {
            issues.append(NoScreensDefinedIssue())
            return .invalid(issues)
        }
        
        // Validate each capture configuration step
        for step in configuration.steps {
            if case let .capture(captureConfig) = step,
               let issue = validateCaptureConfig(captureConfig) {
                issues.append(issue)
            }
        }

        // Check for duplicate screen types
        let duplicates = findDuplicateScreenTypes(in: configuration.steps)
        for (type, indices) in duplicates {
            issues.append(DuplicateScreenTypeIssue(screenType: type, indices: indices))
        }
        
        // Validate screen order
        if let orderIssue = validateScreenOrder(configuration.steps) {
            issues.append(orderIssue)
        }
        
        return issues.isEmpty ? .valid : .invalid(issues)
    }
    
    /// Validates the builder state before building.
    func validateBuilder(screenBuilders: [ScreenBuilder]) -> ValidationState {
        var issues: [FlowValidationIssue] = []
        
        if screenBuilders.isEmpty {
            issues.append(EmptyScreensBlockIssue())
        }
        
        return issues.isEmpty ? .valid : .invalid(issues)
    }
    
    /// Validates and returns only critical issues (blocking issues)
    func validateCritical(configuration: FlowConfiguration) -> [FlowValidationIssue] {
        let validation = validate(configuration: configuration)
        
        guard case .invalid(let issues) = validation else {
            return []
        }
        
        // Filter for critical issues
        return issues.filter { issue in
            issue is NoScreensDefinedIssue ||
            issue is InvalidSelfieCaptureConfigIssue ||
            issue is InvalidDocumentCaptureConfigIssue
        }
    }
    
    /// Validates and returns only warning issues (non-blocking)
    func validateWarnings(configuration: FlowConfiguration) -> [FlowValidationIssue] {
        let validation = validate(configuration: configuration)
        
        guard case .invalid(let issues) = validation else {
            return []
        }
        
        // Filter for warnings
        return issues.filter { issue in
            issue is InvalidScreenOrderIssue
        }
    }
    
    /// Safe validation that returns a Result type
    func validateSafely(_ config: FlowConfiguration) -> Result<Void, ValidationError> {
        let validation = validate(configuration: config)
        
        switch validation {
        case .valid:
            return .success(())
        case .invalid(let issues):
            return .failure(ValidationError(issues: issues))
        }
    }
    
    // MARK: - Private Validation Methods
    
    private func validateScreenOrder(_ steps: [FlowStep]) -> FlowValidationIssue? {
        guard let captureIndex = steps.firstIndex(where: { $0.type == .capture }),
              let previewIndex = steps.firstIndex(where: { $0.type == .preview }) else {
            return nil
        }
        
        if previewIndex < captureIndex {
            return InvalidScreenOrderIssue(
                description: "Preview screen appears before Capture screen"
            )
        }
        
        return nil
    }
    
    /// Validates capture mode-specific configurations
    private func validateCaptureConfig(
        _ config: CaptureScreenConfiguration
    ) -> FlowValidationIssue? {
        switch config.mode {
        case .selfie:
            if config.selfie == nil {
                return InvalidSelfieCaptureConfigIssue(
                    detail: "selfie is required when mode is Selfie"
                )
            }
            return nil
            
        case .document:
            guard let documentConfig = config.document else {
                return InvalidDocumentCaptureConfigIssue(
                    detail: "document is required when mode is Document"
                )
            }
            
            if let aspectRatio = documentConfig.knownIdAspectRatio,
               aspectRatio <= 0 {
                return InvalidDocumentCaptureConfigIssue(
                    detail: "knownIdAspectRatio must be > 0 if provided"
                )
            }
            
            return nil
        }
    }
    
    private func findDuplicateScreenTypes(
        in steps: [FlowStep]
    ) -> [ScreenType: [ScreenIndex]] {
        var typeIndices: [ScreenType: [ScreenIndex]] = [:]
        
        for (index, step) in steps.enumerated() {
            typeIndices[step.type, default: []].append(ScreenIndex(index))
        }
        
        return typeIndices.filter { $0.value.count > 1 }
    }
}
// MARK: - Validation Error (kept for safe validation interface)

struct ValidationError: Error, Equatable {
    let issues: [FlowValidationIssue]

    var errorCount: Int { issues.filter { $0.severity == .error }.count }
    var warningCount: Int { issues.filter { $0.severity == .warning }.count }

    var localizedDescription: String {
        let errorCount = self.errorCount
        let warningCount = self.warningCount
        var summaryParts: [String] = []
        if errorCount > 0 { summaryParts.append("\(errorCount) error(s)") }
        if warningCount > 0 { summaryParts.append("\(warningCount) warning(s)") }
        let summary = summaryParts.isEmpty ? "No issues" : summaryParts.joined(separator: " and ")
        let detailed = issues.enumerated().map { idx, issue in
            var line = "\(idx + 1). \(issue.message)"
            if let fix = issue.suggestedFix { line += "\n   Fix: \(fix)" }
            return line
        }.joined(separator: "\n")
        return "Validation result: \(summary)\n\(detailed)"
    }

    static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        let lhsMessages = lhs.issues.map { $0.message }
        let rhsMessages = rhs.issues.map { $0.message }
        return lhsMessages == rhsMessages
    }
}
