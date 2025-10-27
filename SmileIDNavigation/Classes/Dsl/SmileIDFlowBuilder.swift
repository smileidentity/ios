import Combine
import SwiftUI

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

  // MARK: - Screens Block API

  /// Configure multiple screens in a declarative block
  /// - Parameter configure: Closure to configure screens
  ///
  /// Example:
  /// ```swift
  /// builder.screens { screens in
  ///     instructions { instructions in
  ///             instructions.showAttribution = true
  ///         }
  ///     }
  ///     capture { capture in
  ///             capture.mode = .selfie
  ///         }
  ///     }
  /// }
  /// ```
  public func screens(_ configure: (ScreensBuilder) -> Void) {
    let builder = ScreensBuilder()
    configure(builder)
    screenBuilders.append(contentsOf: builder.screens)
  }

  /// DSL-based screens configuration using `@ScreensDSL` result builder.
  /// This enables a fully declarative style:
  /// ```swift
  /// builder.screens {
  ///     instructions {
  ///         showAttribution = true
  ///     }
  ///     capture {
  ///         mode = .selfie
  ///         selfie { selfie in
  ///             selfie.allowAgentMode = false
  ///         }
  ///     }
  ///     preview {
  ///         allowRetake = true
  ///     }
  /// }
  /// ```
  public func screens(@ScreensDSL _ content: () -> [FlowStep]) {
    let steps = content()
    let builders = steps.map { ScreenBuilder(flowStep: $0) }
    screenBuilders.append(contentsOf: builders)
  }

  /// Validates the current builder configuration without building.
  public func validate() -> ValidationState {
    FlowValidator.shared.validateBuilder(screenBuilders: screenBuilders)
  }

  // MARK: - Flow Build Result

  public enum FlowBuildResult {
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

  public func build() -> FlowBuildResult {
    // Validate builder state
    let builderValidation = validate()

    if case .invalid(let issues) = builderValidation {
      return .invalid(.invalid(issues))
    }

    // Build steps (each ScreenBuilder now returns a FlowStep)
    let steps = screenBuilders.map { $0.build() }

    let configuration = FlowConfiguration(
      steps: steps,
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
      message: "Flow validation failed: \(state.issues.map(\.message).joined(separator: ", "))",
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
        message: "Configuration validation failed: \(issues.map(\.message).joined(separator: ", "))",
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
    SmileConfig(
      enableDebugMode: enableDebugMode,
      allowOfflineMode: allowOfflineMode
    )
  }
}

// MARK: - SmileID Isolated Context

/// Dependency injection context for SmileID
class SmileIDIsolatedContext: ObservableObject {
  static let shared = SmileIDIsolatedContext()

  // dependencies go here
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
  public static func buildBlock(_: Void...) { () }
  public static func buildExpression(_: Void) { () }
  // Allow chaining expressions that return the builder itself (SmileIDFlowBuilder)
  public static func buildExpression(_: SmileIDFlowBuilder) { () }
}
