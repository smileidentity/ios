import SwiftUI

/// A dialog that shows a preview of the image captured by the camera and asks the user to confirm
/// that the image is of acceptable quality.
///
/// - Parameters:
///    - titleText: The title of the dialog
///    - subtitleText: The subtitle of the dialog
///    - painter: The image that the user captured and needs to confirm
///    - confirmButtonText: The text of the button that confirms the image is of acceptable quality
///    - onConfirm: The callback to invoke when the user confirms the image is of acceptable quality
///    - retakeButtonText: The text of the button that allows the user to retake the image
///    -  onRetake: The callback to invoke when the user wants to retake the image
public struct ImageCaptureConfirmationDialog: View {
    public let title: String
    public let subtitle: String
    public let image: UIImage
    public let confirmationButtonText: String
    public let onConfirm: () -> Void
    public let retakeButtonText: String
    public let onRetake: () -> Void
    public let scaleFactor: Double

    public init(
        title: String,
        subtitle: String,
        image: UIImage,
        confirmationButtonText: String,
        onConfirm: @escaping () -> Void,
        retakeButtonText: String,
        onRetake: @escaping () -> Void,
        scaleFactor: Double
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.confirmationButtonText = confirmationButtonText
        self.onConfirm = onConfirm
        self.retakeButtonText = retakeButtonText
        self.onRetake = onRetake
        self.scaleFactor = scaleFactor
    }

    public var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header2)
                    .foregroundColor(SmileID.theme.accent)
                    .lineSpacing(0.98)
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
            }
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scaleFactor, anchor: .center)
                .clipped()
                .cornerRadius(16)
                .frame(height: 256)
            VStack(spacing: 16) {
                Button(action: onConfirm) {
                    Text(confirmationButtonText)
                        .padding(16)
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(SmileID.theme.onDark)
                .background(SmileID.theme.accent)
                .cornerRadius(32)
                .frame(maxWidth: .infinity)
                Button(action: onRetake) {
                    Text(retakeButtonText)
                        .padding(14)
                        .font(SmileID.theme.button)
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(SmileID.theme.accent)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(SmileID.theme.accent, lineWidth: 4)
                )
                .cornerRadius(32)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(SmileID.theme.backgroundMain)
        .cornerRadius(24)
        .shadow(radius: 16)
        .padding(32)
        .preferredColorScheme(.light)
    }
}
