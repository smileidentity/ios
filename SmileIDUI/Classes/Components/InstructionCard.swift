import SwiftUI

struct InstructionCard: View {
  @Environment(\.smileIDTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme

  var icon: Image
  var title: String
  var subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ZStack {
        Circle()
          .fill(color(theme.colors.stroke).opacity(0.25))
        icon
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(color(theme.colors.titleText))
      }
      .frame(width: 44, height: 44)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(theme.typography.cardTitle)
          .foregroundColor(color(theme.colors.titleText))

        Text(subtitle)
          .font(theme.typography.cardSubTitle)
          .foregroundColor(color(theme.colors.cardText))
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(color(theme.colors.cardBackground))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(color(theme.colors.stroke), lineWidth: 1)
    )
  }

  private func color(_ adaptive: AdaptiveColor) -> Color {
    adaptive.standard.resolve(colorScheme)
  }
}

#if DEBUG
  #Preview {
    VStack {
      InstructionCard(
        icon: Image(systemName: "square.stack.3d.up"),
        title: "Remove Obstructions",
        subtitle: "Remove any unnecessary glasses, hats, or any items that may hide your face."
      )
    }
    .padding()
  }
#endif
