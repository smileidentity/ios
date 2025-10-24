import UIKit


// MARK: - Flow Navigation Manager

/// Manages navigation state for the SmileID flow
public class FlowNavigationManager: ObservableObject {
    @Published var navigationPath: [ScreenType] = []
    @Published var currentScreenIndex: Int = 0
    private(set) var collectedData: [ScreenType: ScreenCaptureResult] = [:]
    let configuration: FlowConfiguration
    
    init(configuration: FlowConfiguration) {
        self.configuration = configuration
    }
    
    public func navigateToNext(currentScreenType: ScreenType, result: ScreenCaptureResult? = nil) {
        if let result = result {
            collectedData[currentScreenType] = result
        }
        // Advance index
        if currentScreenIndex < configuration.screens.count - 1 {
            currentScreenIndex += 1
            let nextType = configuration.screens[currentScreenIndex].type
            navigationPath.append(nextType)
        } else {
            // Complete flow
            completeFlow(with: .success(buildCapturedFlowData()))
        }
    }
    
    public func navigateBack() {
        guard currentScreenIndex > 0 else { return }
        navigationPath.removeLast()
        currentScreenIndex -= 1
    }
    
    public func navigateToStart() {
        navigationPath.removeAll()
        currentScreenIndex = 0
    }
    
    private func buildCapturedFlowData() -> CapturedFlowData {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let metadata = CaptureMetadata(
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            screenDensity: Float(UIScreen.main.scale),
            locale: Locale.current.identifier,
            captureMode: configuration.screens.first { $0.type == .capture }
                .flatMap { ($0.configuration as? CaptureScreenConfiguration)?.mode == .selfie ? "selfie" : "document" } ?? "unknown",
            flashUsed: false
        )
        let integrityHash = String(collectedData.hashValue)
        return CapturedFlowData(
            screens: collectedData,
            metadata: metadata,
            integrityHash: integrityHash,
            captureTimestamp: timestamp,
            sdkVersion: "iOS-1.0.0"
        )
    }
    
    public func completeFlow(with result: FlowResult) {
        configuration.onResult(result)
    }
}
