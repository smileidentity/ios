import SwiftUI

public struct SmileIDInstructionsScreen<ContinueButton: View, CancelButton: View>: View {
  // MARK: - Actions

  var onContinue: () -> Void
  var onCancel: () -> Void

  // MARK: - Dependencies

  @Environment(\.smileIDTheme) private var theme
  @Environment(\.colorScheme) private var colorScheme

  // MARK: - Buttons (Injected)

  @ViewBuilder var continueButton: ContinueButton
  @ViewBuilder var cancelButton: CancelButton

  // MARK: - Init

  public init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void,
    @ViewBuilder continueButton: () -> ContinueButton,
    @ViewBuilder cancelButton: () -> CancelButton
  ) {
    self.onContinue = onContinue
    self.onCancel = onCancel
    self.continueButton = continueButton()
    self.cancelButton = cancelButton()
  }

  // MARK: - Body

  public var body: some View {
    ZStack(alignment: .topTrailing) {
      background

      // Content + bottom CTA
      VStack(spacing: 0) {
        content

        // Bottom area with sticky CTA
        VStack(spacing: 12) {
          Text("By clicking on Take Selfie, you consent to provide us with the requested data.")
            .font(theme.typography.body)
            .foregroundColor(color(theme.colors.cardText))
            .multilineTextAlignment(.center)

          continueButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
      }
    }
  }

  // MARK: - Subviews

  private var background: some View {
    color(theme.colors.background)
      .edgesIgnoringSafeArea(.all)
  }

  private var content: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 20) {
        // Large card container with heading + rules
        VStack(alignment: .leading, spacing: 16) {
          Text("Let’s verify your selfie")
            .font(theme.typography.pageHeading.weight(.bold))
            .foregroundColor(color(theme.colors.titleText))

          Text("Your selfie is encrypted and used only for verification.")
            .font(theme.typography.subHeading)
            .foregroundColor(color(theme.colors.cardText))

          // Rule cards
          InstructionCard(
            icon: Image(systemName: "square.stack.3d.up"),
            title: "Good Light",
            subtitle: "Make sure you are in a well lit environment where your face is clear and visible."
					)

          InstructionCard(
            icon: Image(systemName: "square.stack.3d.up"),
            title: "Face Camera",
            subtitle: "Keep your face centred and look straight into the camera."
					)

          InstructionCard(
            icon: Image(systemName: "square.stack.3d.up"),
            title: "Remove Obstructions",
            subtitle: "Remove any unnecessary glasses, hats, or any items that may hide your face."
					)
        }
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color(theme.colors.cardBackground))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(color(theme.colors.stroke), lineWidth: colorScheme == .dark ? 0.5 : 0)
        )

        // Warning callout
        WarningCallout()
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
      .padding(.bottom, 12)
    }
  }

  // MARK: - Helpers

  private func color(_ adaptive: AdaptiveColor) -> Color {
    adaptive.standard.resolve(colorScheme)
  }
}

public extension SmileIDInstructionsScreen where ContinueButton == SmileIDButton, CancelButton == SmileIDButton {
  init(
    onContinue: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.init(
      onContinue: onContinue,
      onCancel: onCancel,
      continueButton: {
        // Default CTA text matches the mock
        SmileIDButton(text: "Take Selfie", onClick: onContinue)
      },
      cancelButton: {
        SmileIDButton(text: "Cancel", onClick: onCancel)
      }
    )
  }
}

#if DEBUG
  #Preview {
    NavigationView {
      SmileIDInstructionsScreen(
        onContinue: {},
        onCancel: {}
      )
    }
  }
#endif
