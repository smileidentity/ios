import Foundation
import SwiftUI

/// Displays instructions to the user for how to take a good quality selfie
///
/// - Parameters:
///    - showAttribution: Whether or not to show the SmileID attribution
///    - onInstructionsAcknowledged: The callback to invoke when the user acknowledges the instructions
public struct SmartSelfieInstructionsScreen: View {
    public let showAttribution: Bool
    public let onInstructionsAcknowledged: () -> Void
    public init(showAttribution: Bool, onInstructionsAcknowledged: @escaping () -> Void) {
        self.showAttribution = showAttribution
        self.onInstructionsAcknowledged = onInstructionsAcknowledged
    }

    public var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderIcon)
                        .padding(24)
                    VStack(spacing: 16) {
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Header"))
                            .multilineTextAlignment(.center)
                            .font(SmileID.theme.header1)
                            .foregroundColor(SmileID.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"))
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
                        HStack(spacing: 16) {
                            Image(uiImage: SmileIDResourcesHelper.Face)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.RemoveObstructions"
                                ))
                                .font(SmileID.theme.header4)
                                .foregroundColor(SmileID.theme.accent)
                                Text(SmileIDResourcesHelper.localizedString(
                                    for: "Instructions.RemoveObstructionsBody"
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

            VStack(spacing: 8) {
                SmileButton(
                    title: "Action.TakePhoto",
                    clicked: onInstructionsAcknowledged
                )

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                }
            }
        }
        .padding(.horizontal, 16)
        .preferredColorScheme(.light)
    }
}
