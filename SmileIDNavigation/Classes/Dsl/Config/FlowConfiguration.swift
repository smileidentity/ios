// MARK: - Flow Configuration

/// Complete configuration for a SmileID flow.
public struct FlowConfiguration {
    let screens: [Screen]
    let enableDebugMode: Bool
    let allowOfflineMode: Bool
    let onResult: (FlowResult) -> Void
    
    init(
        screens: [Screen],
        enableDebugMode: Bool = false,
        allowOfflineMode: Bool = false,
        onResult: @escaping (FlowResult) -> Void = { _ in }
    ) {
        self.screens = screens
        self.enableDebugMode = enableDebugMode
        self.allowOfflineMode = allowOfflineMode
        self.onResult = onResult
    }
}

// MARK: - Screen

/// Represents a single screen in the flow tying a ScreenConfiguration to its type.
public struct Screen {
    let configuration: ScreenConfiguration
    
    var type: ScreenType {
        return configuration.type
    }
    
    init(configuration: ScreenConfiguration) {
        self.configuration = configuration
    }
}

// MARK: - Equatable & Hashable Conformance (Optional but recommended)

extension FlowConfiguration: Equatable {
    public static func == (lhs: FlowConfiguration, rhs: FlowConfiguration) -> Bool {
        return lhs.screens == rhs.screens &&
               lhs.enableDebugMode == rhs.enableDebugMode &&
               lhs.allowOfflineMode == rhs.allowOfflineMode
    }
}

extension FlowConfiguration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(screens)
        hasher.combine(enableDebugMode)
        hasher.combine(allowOfflineMode)
    }
}

extension Screen: Equatable {
    public static func == (lhs: Screen, rhs: Screen) -> Bool {
        return lhs.configuration.isEqual(to: rhs.configuration)
    }
}

extension Screen: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration.hashValue)
    }
}
