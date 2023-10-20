import SwiftUI

struct DocumentCaptureInstructionsScreen: View {
    let title: String
    let subtitle: String
    let showAttribution: Bool
    let allowPhotoFromGallery: Bool
    let showSkipButton: Bool
    let onSkip: () -> Void
    let onInstructionsAcknowledgedSelectFromGallery: () -> Void
    let onInstructionsAcknowledgedTakePhoto: () -> Void

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderDocumentIcon)
                        .padding(24)
                    VStack(spacing: 16) {
                        Text(title)
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header1)
                            .foregroundColor(SmileID.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header5)
                            .foregroundColor(SmileID.theme.tertiary)
                            .lineSpacing(1.3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                        .padding(.bottom, 48)

                    VStack(alignment: .leading, spacing: 32) {
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.Light)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.GoodLight"
                                ))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.GoodLightBody"
                                ))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.ClearImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.ClearImage"
                                ))
                                    .font(SmileID.theme.header4)
                                    .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.ClearImageBody"
                                ))
                                    .multilineTextAlignment(.leading)
                                    .font(SmileID.theme.header5)
                                    .foregroundColor(SmileID.theme.tertiary)
                                    .lineSpacing(1.3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            VStack(spacing: 4) {
                if showSkipButton {
                    Button(
                        action: onSkip,
                        label: {
                            Text(SmileIDResourcesHelper.localizedString(for: "Action.Skip"))
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.button)
                                .foregroundColor(SmileID.theme.tertiary.opacity(0.8))
                        }
                    )
                        .frame(height: 48)
                }

                SmileButton(
                    title: "Action.TakePhoto",
                    clicked: onInstructionsAcknowledgedTakePhoto
                )

                if allowPhotoFromGallery {
                    SmileButton(
                        style: .alternate,
                        title: "Action.UploadPhoto",
                        clicked: onInstructionsAcknowledgedSelectFromGallery
                    )
                }
                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }
            }
        }
            .padding(.horizontal, 16)
    }
}
