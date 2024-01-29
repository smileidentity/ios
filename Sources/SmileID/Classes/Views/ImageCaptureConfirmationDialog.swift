import SwiftUI

struct ImageCaptureConfirmationDialog: View {
    let title: String
    let subtitle: String
    let image: UIImage
    let confirmationButtonText: String
    let onConfirm: () -> Void
    let retakeButtonText: String
    let onRetake: () -> Void
    let scaleFactor: Double

    var body: some View {
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
    }
}
