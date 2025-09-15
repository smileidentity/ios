import SwiftUI

private struct SmileIDThemeKey: EnvironmentKey {
  static var defaultValue: SmileIDTheme = DefaultTheme()
}

public extension EnvironmentValues {
  var smileIDTheme: SmileIDTheme {
    get { self[SmileIDThemeKey.self] }
    set { self[SmileIDThemeKey.self] = newValue }
  }
}

public extension View {
  @inlinable func smileIDTheme(_ theme: SmileIDTheme) -> some View {
    environment(\.smileIDTheme, theme)
  }
}
