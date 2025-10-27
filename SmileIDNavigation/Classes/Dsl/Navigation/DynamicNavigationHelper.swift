import Foundation

/// Helper responsible for advancing or reversing flow navigation without screens hardcoding destinations.
public enum DynamicNavigationHelper {
  public static func navigateToNextInFlow(
    manager: FlowNavigationManager,
    currentScreenType: ScreenType,
    result: ScreenCaptureResult? = nil
  ) {
    manager.navigateToNext(currentScreenType: currentScreenType, result: result)
  }

  public static func navigateBackInFlow(manager: FlowNavigationManager) {
    manager.navigateBack()
  }
}
