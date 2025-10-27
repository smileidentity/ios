import SwiftUI

// MARK: - Screens DSL Result Builder

@resultBuilder
public struct ScreensDSL {
  public static func buildBlock(_ components: FlowStep...) -> [FlowStep] { components }
  public static func buildOptional(_ component: [FlowStep]?) -> [FlowStep] { component ?? [] }
  public static func buildEither(first component: [FlowStep]) -> [FlowStep] { component }
  public static func buildEither(second component: [FlowStep]) -> [FlowStep] { component }
  public static func buildArray(_ components: [[FlowStep]]) -> [FlowStep] { components.flatMap { $0 } }
}

// MARK: - Top-level Screen Constructors (DSL)

/// Creates an instructions screen step using a declarative DSL block.
/// Example:
/// ```swift
/// instructions { instructions in
///     instructions.showAttribution = true
/// }
/// ```
public func instructions(_ configure: (InstructionsConfigBuilder) -> Void) -> FlowStep {
  let builder = InstructionsConfigBuilder()
  configure(builder)
  return .instructions(builder.build())
}

/// Creates a capture screen step.
/// Example:
/// ```swift
/// capture { capture in
///     capture.mode = .selfie
///     selfie { selfie in
///         selfie.allowAgentMode = false
///     }
/// }
/// ```
public func capture(_ configure: (CaptureConfigBuilder) -> Void) -> FlowStep {
  let builder = CaptureConfigBuilder()
  configure(builder)
  return .capture(builder.build())
}

/// Creates a preview screen step.
/// Example:
/// ```swift
/// preview { capture in
///     capture.allowRetake = true
/// }
/// ```
public func preview(_ configure: (PreviewConfigBuilder) -> Void) -> FlowStep {
  let builder = PreviewConfigBuilder()
  configure(builder)
  return .preview(builder.build())
}

// MARK: - Screen Builder

public class ScreenBuilder {
  var configuration: ScreenConfiguration?

  @discardableResult
  public func instructions(_ configure: (InstructionsConfigBuilder) -> Void) -> ScreenBuilder {
    let builder = InstructionsConfigBuilder()
    configure(builder)
    configuration = builder.build()
    return self
  }

  @discardableResult
  public func capture(_ configure: (CaptureConfigBuilder) -> Void) -> ScreenBuilder {
    let builder = CaptureConfigBuilder()
    configure(builder)
    configuration = builder.build()
    return self
  }

  @discardableResult
  public func preview(_ configure: (PreviewConfigBuilder) -> Void) -> ScreenBuilder {
    let builder = PreviewConfigBuilder()
    configure(builder)
    configuration = builder.build()
    return self
  }

  public func build() -> FlowStep {
    guard let config = configuration else {
      fatalError("Screen configuration not set")
    }
    // Map underlying configuration to typed FlowStep
    if let instructions = config as? InstructionsScreenConfiguration { return .instructions(instructions) }
    if let capture = config as? CaptureScreenConfiguration { return .capture(capture) }
    if let preview = config as? PreviewScreenConfiguration { return .preview(preview) }
    fatalError("Unknown configuration type: \(config)")
  }
}

// MARK: - DSL Convenience Initializers

extension ScreenBuilder {
  /// Convenience init from a concrete `ScreenConfiguration` used by the DSL adapter.
  convenience init(configuration: ScreenConfiguration) {
    self.init()
    self.configuration = configuration
  }

  /// Convenience init from a `FlowStep` enum case.
  convenience init(flowStep: FlowStep) {
    self.init()
    switch flowStep {
    case .instructions(let cfg):
      self.configuration = cfg
    case .capture(let cfg):
      self.configuration = cfg
    case .preview(let cfg):
      self.configuration = cfg
    }
  }
}

// MARK: - Screens Container Builder

public class ScreensBuilder {
  var screens: [ScreenBuilder] = []

  public init() {}

  /// Creates and adds a screen to the collection
  /// - Parameter configure: Closure to configure the screen
  /// - Returns: The created ScreenBuilder (for potential chaining)
  @discardableResult
  public func screen(_ configure: (ScreenBuilder) -> Void) -> ScreenBuilder {
    let builder = ScreenBuilder()
    configure(builder)
    screens.append(builder)
    return builder
  }
}

// MARK: - Capture Config Builder

public class CaptureConfigBuilder {
  public var mode: Mode = .selfie
  private var selfieConfig: SelfieCaptureConfigBuilder?
  private var documentConfig: DocumentCaptureConfigBuilder?

  public func selfie(_ configure: (SelfieCaptureConfigBuilder) -> Void) {
    let builder = SelfieCaptureConfigBuilder()
    configure(builder)
    selfieConfig = builder
  }

  public func document(_ configure: (DocumentCaptureConfigBuilder) -> Void) {
    let builder = DocumentCaptureConfigBuilder()
    configure(builder)
    documentConfig = builder
  }

  public func build() -> CaptureScreenConfiguration {
    CaptureScreenConfiguration(
      mode: mode,
      selfie: selfieConfig?.build(),
      document: documentConfig?.build()
    )
  }
}

// MARK: - Selfie Capture Config Builder

public class SelfieCaptureConfigBuilder {
  public var allowAgentMode: Bool = false

  public func build() -> SelfieCaptureConfig {
    SelfieCaptureConfig(allowAgentMode: allowAgentMode)
  }
}

// MARK: - Document Capture Config Builder

public class DocumentCaptureConfigBuilder {
  public var autoCapture: Bool = true
  public var autoCaptureTimeout: TimeInterval = 10.0
  public var allowGalleryUpload: Bool = false
  public var captureBothSides: Bool = true
  public var allowSkipBack: Bool = false
  public var knownIdAspectRatio: Float?

  public func build() -> DocumentCaptureConfig {
    DocumentCaptureConfig(
      autoCapture: autoCapture,
      autoCaptureTimeout: autoCaptureTimeout,
      allowGalleryUpload: allowGalleryUpload,
      captureBothSides: captureBothSides,
      allowSkipBack: allowSkipBack,
      knownIdAspectRatio: knownIdAspectRatio
    )
  }
}

// MARK: - Preview Config Builder

public class PreviewConfigBuilder {
  public var allowRetake: Bool = true

  public func build() -> PreviewScreenConfiguration {
    PreviewScreenConfiguration(allowRetake: allowRetake)
  }
}

// MARK: - Instructions Config Builder

public class InstructionsConfigBuilder {
  public var showAttribution: Bool = false
  public var continueButton: ((() -> Void) -> AnyView)?

  public func build() -> InstructionsScreenConfiguration {
    InstructionsScreenConfiguration(
      showAttribution: showAttribution,
      continueButton: continueButton ?? InstructionsDefaults.continueButton
    )
  }
}
