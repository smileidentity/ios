import SwiftUI

// MARK: - Screen Configuration Protocol

/// Sealed hierarchy for all screen configurations.
public protocol ScreenConfiguration {
    var type: ScreenType { get }
}

// MARK: - Instructions Screen Configuration

public struct InstructionsScreenConfiguration: ScreenConfiguration {
    public let showAttribution: Bool
    public let continueButton: ((@escaping () -> Void) -> AnyView)?
    
    public var type: ScreenType {
        return .instructions
    }
    
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
    
    public var type: ScreenType {
        return .preview
    }
    
    public init(allowRetake: Bool = true) {
        self.allowRetake = allowRetake
    }
}

// MARK: - Capture Screen Configuration

public struct CaptureScreenConfiguration: ScreenConfiguration {
    public let mode: Mode
    public let selfie: SelfieCaptureConfig?
    public let document: DocumentCaptureConfig?
    
    public var type: ScreenType {
        return .capture
    }
    
    public init(
        mode: Mode,
        selfie: SelfieCaptureConfig? = nil,
        document: DocumentCaptureConfig? = nil
    ) {
        self.mode = mode
        self.selfie = selfie
        self.document = document
    }
}

// MARK: - Selfie Capture Config

public struct SelfieCaptureConfig {
    public let allowAgentMode: Bool
    
    public init(allowAgentMode: Bool = false) {
        self.allowAgentMode = allowAgentMode
    }
}

// MARK: - Document Capture Config

public struct DocumentCaptureConfig {
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

public enum Mode {
    case selfie
    case document
}

// MARK: - Document Side

public enum DocumentSide {
    case front
    case back
}

// MARK: - SmileID SDK Configuration

public struct SmileConfig {
    public let enableDebugMode: Bool
    public let allowOfflineMode: Bool
    
    public init(
        enableDebugMode: Bool = false,
        allowOfflineMode: Bool = false
    ) {
        self.enableDebugMode = enableDebugMode
        self.allowOfflineMode = allowOfflineMode
    }
}

// MARK: - Equatable Conformance

extension InstructionsScreenConfiguration: Equatable {
    public static func == (lhs: InstructionsScreenConfiguration, rhs: InstructionsScreenConfiguration) -> Bool {
        return lhs.showAttribution == rhs.showAttribution
    }
}

extension PreviewScreenConfiguration: Equatable {
    public static func == (lhs: PreviewScreenConfiguration, rhs: PreviewScreenConfiguration) -> Bool {
        return lhs.allowRetake == rhs.allowRetake
    }
}

extension CaptureScreenConfiguration: Equatable {
    public static func == (lhs: CaptureScreenConfiguration, rhs: CaptureScreenConfiguration) -> Bool {
        return lhs.mode == rhs.mode &&
               lhs.selfie == rhs.selfie &&
               lhs.document == rhs.document
    }
}

extension SelfieCaptureConfig: Equatable {
    public static func == (lhs: SelfieCaptureConfig, rhs: SelfieCaptureConfig) -> Bool {
        return lhs.allowAgentMode == rhs.allowAgentMode
    }
}

extension DocumentCaptureConfig: Equatable {
    public static func == (lhs: DocumentCaptureConfig, rhs: DocumentCaptureConfig) -> Bool {
        return lhs.autoCapture == rhs.autoCapture &&
               lhs.autoCaptureTimeout == rhs.autoCaptureTimeout &&
               lhs.allowGalleryUpload == rhs.allowGalleryUpload &&
               lhs.captureBothSides == rhs.captureBothSides &&
               lhs.allowSkipBack == rhs.allowSkipBack &&
               lhs.knownIdAspectRatio == rhs.knownIdAspectRatio
    }
}

extension SmileConfig: Equatable {
    public static func == (lhs: SmileConfig, rhs: SmileConfig) -> Bool {
        return lhs.enableDebugMode == rhs.enableDebugMode &&
               lhs.allowOfflineMode == rhs.allowOfflineMode
    }
}

// MARK: - Hashable Conformance

extension InstructionsScreenConfiguration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(showAttribution)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(showAttribution)
        return hasher.finalize()
    }
}

extension PreviewScreenConfiguration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(allowRetake)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(allowRetake)
        return hasher.finalize()
    }
}

extension CaptureScreenConfiguration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
        hasher.combine(selfie)
        hasher.combine(document)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(mode)
        hasher.combine(selfie)
        hasher.combine(document)
        return hasher.finalize()
    }
}

extension SelfieCaptureConfig: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(allowAgentMode)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(allowAgentMode)
        return hasher.finalize()
    }
}

extension DocumentCaptureConfig: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(autoCapture)
        hasher.combine(autoCaptureTimeout)
        hasher.combine(allowGalleryUpload)
        hasher.combine(captureBothSides)
        hasher.combine(allowSkipBack)
        hasher.combine(knownIdAspectRatio)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(autoCapture)
        hasher.combine(autoCaptureTimeout)
        hasher.combine(allowGalleryUpload)
        hasher.combine(captureBothSides)
        hasher.combine(allowSkipBack)
        hasher.combine(knownIdAspectRatio)
        return hasher.finalize()
    }
}

extension SmileConfig: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableDebugMode)
        hasher.combine(allowOfflineMode)
    }
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(enableDebugMode)
        hasher.combine(allowOfflineMode)
        return hasher.finalize()
    }
}

// MARK: - Helper Extensions for ScreenConfiguration

extension ScreenConfiguration {
    func isEqual(to other: ScreenConfiguration) -> Bool {
        switch (self, other) {
        case (let lhs as InstructionsScreenConfiguration, let rhs as InstructionsScreenConfiguration):
            return lhs == rhs
        case (let lhs as PreviewScreenConfiguration, let rhs as PreviewScreenConfiguration):
            return lhs == rhs
        case (let lhs as CaptureScreenConfiguration, let rhs as CaptureScreenConfiguration):
            return lhs == rhs
        default:
            return false
        }
    }
    
    var hashValue: Int {
        switch self {
        case let config as InstructionsScreenConfiguration:
            return config.hashValue
        case let config as PreviewScreenConfiguration:
            return config.hashValue
        case let config as CaptureScreenConfiguration:
            return config.hashValue
        default:
            return 0
        }
    }
}

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
