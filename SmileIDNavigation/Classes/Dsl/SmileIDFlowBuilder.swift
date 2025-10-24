import SwiftUI
import Combine

// MARK: - SmileID Flow Builder

/// Builder for configuring a complete SmileID flow.
public class SmileIDFlowBuilder: ObservableObject {
    
    // MARK: - Properties
    
    private var screenBuilders: [ScreenBuilder] = []
    private var smileConfigData: SmileConfig?
    
    /// Callback invoked when the flow completes (success or failure)
    public var onResult: (FlowResult) -> Void = { _ in }
    
    // MARK: - Configuration Methods
    
    /// Configure global SmileID settings
    public func smileConfig(_ configure: (SmileConfigBuilder) -> Void) {
        let builder = SmileConfigBuilder()
        configure(builder)
        smileConfigData = builder.build()
    }
    
    /// Configure the screens in this flow
    public func screens(@ScreensResultBuilder _ content: () -> [ScreenBuilder]) {
        screenBuilders = content()
    }
    
    /// Validates the current builder configuration without building.
    func validate() -> ValidationState {
        return FlowValidator.shared.validateBuilder(screenBuilders: screenBuilders)
    }
    
    // MARK: - Flow Build Result
    
    enum FlowBuildResult {
        case success(FlowConfiguration)
        case invalid(ValidationState)
        
        var isSuccess: Bool {
            if case .success = self {
                return true
            }
            return false
        }
        
        var configuration: FlowConfiguration? {
            if case .success(let config) = self {
                return config
            }
            return nil
        }
        
        var validationState: ValidationState? {
            if case .invalid(let state) = self {
                return state
            }
            return nil
        }
    }
    
    // MARK: - Build Method
    
       func build() -> FlowBuildResult {
        // Validate builder state
        let builderValidation = validate()
        
        if case .invalid(let issues) = builderValidation {
            return .invalid(.invalid(issues))
        }
        
    // Build configuration (each ScreenBuilder already returns a Screen)
    let screens = screenBuilders.map { $0.build() }
        
        let configuration = FlowConfiguration(
            screens: screens,
            enableDebugMode: smileConfigData?.enableDebugMode ?? false,
            allowOfflineMode: smileConfigData?.allowOfflineMode ?? false,
            onResult: onResult
        )
        
        return .success(configuration)
    }
    
    // MARK: - Render Methods
    
    @ViewBuilder
    public func render() -> some View {
        let isDebugMode = smileConfigData?.enableDebugMode ?? false
        
        switch build() {
        case .invalid(let validationState):
            renderInvalidState(validationState, isDebugMode: isDebugMode)
            
        case .success(let configuration):
            renderValidConfiguration(configuration, isDebugMode: isDebugMode)
        }
    }
    
    @ViewBuilder
    private func renderInvalidState(_ state: ValidationState, isDebugMode: Bool) -> some View {
        let error = ValidationException(
            message: "Flow validation failed: \(state.issues.map { $0.message }.joined(separator: ", "))",
            validationState: state
        )
        
        // Call onResult with failure
        let _ = onResult(.failure(error))
        
        if isDebugMode {
            ValidationErrorView(validationState: state)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func renderValidConfiguration(_ configuration: FlowConfiguration, isDebugMode: Bool) -> some View {
        // Validate the configuration
        let configValidation = FlowValidator.shared.validate(configuration: configuration)
        
        switch configValidation {
        case .invalid(let issues):
            let error = ValidationException(
                message: "Configuration validation failed: \(issues.map { $0.message }.joined(separator: ", "))",
                validationState: .invalid(issues)
            )
            
            let _ = onResult(.failure(error))
            
            if isDebugMode {
                ValidationErrorView(validationState: .invalid(issues))
            } else {
                EmptyView()
            }
            
        case .valid:
            FlowNavigationView(configuration: configuration)
        }
    }
}

// MARK: - SmileConfig Builder

/// Builder for SmileID global configuration
public class SmileConfigBuilder {
    public var enableDebugMode: Bool = false
    public var allowOfflineMode: Bool = false
    
    public func build() -> SmileConfig {
        return SmileConfig(
            enableDebugMode: enableDebugMode,
            allowOfflineMode: allowOfflineMode
        )
    }
}

// MARK: - SmileID Isolated Context

/// Dependency injection context for SmileID
class SmileIDIsolatedContext: ObservableObject {
    static let shared = SmileIDIsolatedContext()
    
    // Add your dependencies here
    // Example: var apiService: APIService
    
    private init() {
        // Initialize dependencies
    }
}


// MARK: - DSL Entry Point

/// DSL entry point for creating a SmileID flow.
public struct SmileIDFlow: View {
    private let builder: SmileIDFlowBuilder
    
    public init(@SmileIDFlowBuilderDSL _ configure: (SmileIDFlowBuilder) -> Void) {
        let builder = SmileIDFlowBuilder()
        configure(builder)
        self.builder = builder
    }
    
    public var body: some View {
        builder.render()
    }
}

// MARK: - Result Builder for SmileIDFlowBuilder

@resultBuilder
public struct SmileIDFlowBuilderDSL {
    public static func buildBlock(_ components: Void...) -> Void {
        return ()
    }
}
