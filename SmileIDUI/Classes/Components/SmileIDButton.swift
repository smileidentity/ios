import SwiftUI

public struct SmileIDButton: View {
  // MARK: - Public API

  var text: String
  var onClick: () -> Void

  // MARK: - Theme

  @Environment(\.smileIDTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme

  init(
    text: String,
    onClick: @escaping () -> Void
  ) {
    self.text = text
    self.onClick = onClick
  }

  public var body: some View {
    Button(action: onClick) {
      Text(text)
        .font(theme.typography.button)
        .foregroundColor(color(theme.colors.primaryForeground))
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(PlainButtonStyle())
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(color(theme.colors.primary))
    )
  }

  // MARK: - Helpers

  private func color(_ adaptive: AdaptiveColor) -> Color {
    adaptive.standard.resolve(colorScheme)
  }
}
