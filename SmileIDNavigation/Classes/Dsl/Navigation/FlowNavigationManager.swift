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
    if let result {
      collectedData[currentScreenType] = result
    }
    // Advance index
    if currentScreenIndex < configuration.steps.count - 1 {
      currentScreenIndex += 1
      let nextType = configuration.steps[currentScreenIndex].type
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
      captureMode: configuration.steps.first { $0.type == .capture }
        .flatMap { step -> String in
          if case .capture(let cfg) = step { return cfg.mode == .selfie ? "selfie" : "document" }
          return "unknown"
        } ?? "unknown",
      flashUsed: false
    )
    var hasher = Hasher()
    for (type, result) in collectedData.sorted(by: { $0.key.hashValue < $1.key.hashValue }) {
      hasher.combine(type)
      hasher.combine(String(describing: result))
    }
    let integrityHash = String(hasher.finalize())
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
