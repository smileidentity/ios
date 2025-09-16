import SwiftUI

struct WarningCallout: View {
  @Environment(\.smileIDTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(iconColor)
        .padding(.top, 2)

      Text("Avoid poor lighting, accessories, or looking away as this may lead to rejection of your selfie.")
        .font(theme.typography.body)
        .foregroundColor(textColor)

      Spacer(minLength: 0)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(backgroundFill)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(color(theme.colors.warningStroke), lineWidth: 1)
    )
  }

  private var backgroundFill: Color {
    let fill = color(theme.colors.warningFill)
    return colorScheme == .dark ? fill : fill.opacity(0.10)
  }

  private var textColor: Color {
    colorScheme == .dark ? color(theme.colors.primaryForeground) : color(theme.colors.warningFill)
  }

  private var iconColor: Color {
    color(theme.colors.warningIcon)
  }

  private func color(_ adaptive: AdaptiveColor) -> Color {
    adaptive.standard.resolve(colorScheme)
  }
}

#if DEBUG
  #Preview {
    WarningCallout()
  }
#endif
