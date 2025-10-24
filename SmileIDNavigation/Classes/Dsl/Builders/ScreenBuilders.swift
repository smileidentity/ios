import SwiftUI

// MARK: - Screen Builder

public class ScreenBuilder {
    private var configuration: ScreenConfiguration?
    
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
        return CaptureScreenConfiguration(
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
        return SelfieCaptureConfig(allowAgentMode: allowAgentMode)
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
        return DocumentCaptureConfig(
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
        return PreviewScreenConfiguration(allowRetake: allowRetake)
    }
}

// MARK: - Instructions Config Builder

public class InstructionsConfigBuilder {
    public var showAttribution: Bool = false
    public var continueButton: (((() -> Void)) -> AnyView)?
    
    public func build() -> InstructionsScreenConfiguration {
        return InstructionsScreenConfiguration(
            showAttribution: showAttribution,
            continueButton: continueButton ?? InstructionsDefaults.continueButton
        )
    }
}
