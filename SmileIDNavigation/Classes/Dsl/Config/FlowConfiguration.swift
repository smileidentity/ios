// MARK: - Flow Configuration (FlowStep-based)

/// Complete configuration for a SmileID flow using typed FlowStep enum for stronger type safety.
public struct FlowConfiguration {
  public let steps: [FlowStep]
  public let enableDebugMode: Bool
  public let allowOfflineMode: Bool
  public let onResult: (FlowResult) -> Void

  public init(
    steps: [FlowStep],
    enableDebugMode: Bool = false,
    allowOfflineMode: Bool = false,
    onResult: @escaping (FlowResult) -> Void = { _ in }
  ) {
    self.steps = steps
    self.enableDebugMode = enableDebugMode
    self.allowOfflineMode = allowOfflineMode
    self.onResult = onResult
  }
}

// MARK: - FlowStep Enum

/// Represents a typed step in the SmileID flow with its associated configuration.
public enum FlowStep: Equatable, Hashable {
  case instructions(InstructionsScreenConfiguration)
  case capture(CaptureScreenConfiguration)
  case preview(PreviewScreenConfiguration)

  public var type: ScreenType {
    switch self {
    case .instructions: return .instructions
    case .capture: return .capture
    case .preview: return .preview
    }
  }
}

// MARK: - Equatable & Hashable Conformance

extension FlowConfiguration: Equatable {
  public static func == (lhs: FlowConfiguration, rhs: FlowConfiguration) -> Bool {
    lhs.steps == rhs.steps &&
      lhs.enableDebugMode == rhs.enableDebugMode &&
      lhs.allowOfflineMode == rhs.allowOfflineMode
  }
}

extension FlowConfiguration: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(steps)
    hasher.combine(enableDebugMode)
    hasher.combine(allowOfflineMode)
  }
}
