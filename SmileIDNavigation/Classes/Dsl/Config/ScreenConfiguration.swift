import SwiftUI

// MARK: - Screen Configuration Protocol

/// Root protocol for all screen configurations in the flow.
public protocol ScreenConfiguration: Equatable, Hashable {
    var type: ScreenType { get }
}

// MARK: - Instructions Screen Configuration

public struct InstructionsScreenConfiguration: ScreenConfiguration {
    public let showAttribution: Bool
    /// Custom continue button factory. Not part of equality for predictability.
    public let continueButton: ((@escaping () -> Void) -> AnyView)?

    public var type: ScreenType { .instructions }

    public init(
        showAttribution: Bool = false,
        continueButton: ((@escaping () -> Void) -> AnyView)? = nil
    ) {
        self.showAttribution = showAttribution
        self.continueButton = continueButton ?? InstructionsDefaults.continueButton
    }
}

// MARK: - Preview Screen Configuration

public struct PreviewScreenConfiguration: ScreenConfiguration {
    public let allowRetake: Bool
    public var type: ScreenType { .preview }
    public init(allowRetake: Bool = true) { self.allowRetake = allowRetake }
}

// MARK: - Capture Screen Configuration

public struct CaptureScreenConfiguration: ScreenConfiguration {
    public let mode: Mode
    public let selfie: SelfieCaptureConfig?
    public let document: DocumentCaptureConfig?
    public var type: ScreenType { .capture }
    public init(mode: Mode, selfie: SelfieCaptureConfig? = nil, document: DocumentCaptureConfig? = nil) {
        self.mode = mode
        self.selfie = selfie
        self.document = document
    }
}

// MARK: - Selfie Capture Config

public struct SelfieCaptureConfig: Hashable { public let allowAgentMode: Bool; public init(allowAgentMode: Bool = false) { self.allowAgentMode = allowAgentMode } }

// MARK: - Document Capture Config

public struct DocumentCaptureConfig: Hashable {
    public let autoCapture: Bool
    public let autoCaptureTimeout: TimeInterval
    public let allowGalleryUpload: Bool
    public let captureBothSides: Bool
    public let allowSkipBack: Bool
    public let knownIdAspectRatio: Float?
    public init(
        autoCapture: Bool = true,
        autoCaptureTimeout: TimeInterval = 10.0,
        allowGalleryUpload: Bool = false,
        captureBothSides: Bool = true,
        allowSkipBack: Bool = false,
        knownIdAspectRatio: Float? = nil
    ) {
        self.autoCapture = autoCapture
        self.autoCaptureTimeout = autoCaptureTimeout
        self.allowGalleryUpload = allowGalleryUpload
        self.captureBothSides = captureBothSides
        self.allowSkipBack = allowSkipBack
        self.knownIdAspectRatio = knownIdAspectRatio
    }
}

// MARK: - Screen Type

public enum ScreenType {
    case instructions
    case capture
    case preview
}

// MARK: - Capture Mode

public enum Mode { case selfie, document }

// MARK: - Document Side

public enum DocumentSide { case front, back }

// MARK: - SmileID SDK Configuration

public struct SmileConfig { public let enableDebugMode: Bool; public let allowOfflineMode: Bool; public init(enableDebugMode: Bool = false, allowOfflineMode: Bool = false) { self.enableDebugMode = enableDebugMode; self.allowOfflineMode = allowOfflineMode } }

// MARK: - Equatable Conformance

// MARK: - Custom Equatable where closures exist
extension InstructionsScreenConfiguration {
    public static func == (lhs: InstructionsScreenConfiguration, rhs: InstructionsScreenConfiguration) -> Bool {
        lhs.showAttribution == rhs.showAttribution
    }
}

// MARK: - Hashable Conformance

extension InstructionsScreenConfiguration: Hashable { public func hash(into hasher: inout Hasher) { hasher.combine(showAttribution) } }
extension CaptureScreenConfiguration: Hashable { public func hash(into hasher: inout Hasher) { hasher.combine(mode); hasher.combine(selfie); hasher.combine(document) } }
// MARK: - Instructions Defaults

struct InstructionsDefaults {
    static let continueButton: (@escaping () -> Void) -> AnyView = { onClick in
        AnyView(
            Button(action: onClick) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        )
    }
}
