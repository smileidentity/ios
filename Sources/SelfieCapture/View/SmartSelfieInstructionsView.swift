import SwiftUI

struct SmartSelfieInstructionsView: View {
    var body: some View {
        VStack {
            Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderIcon)
                .padding(.bottom, 27)
            VStack(spacing: 32) {
                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Header"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header1)
                    .foregroundColor(SmileIdentity.theme.accent)
                    .lineSpacing(0.98)
                Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                    .lineSpacing(1.3)
            }
            .padding(.bottom, 47)
            VStack(alignment: .leading, spacing: 30) {
                makeInstruction(title: "Instructions.GoodLight",
                                body: "Instructions.GoodLightBody",
                                image: Constants.ImageName.light)
                makeInstruction(title: "Instructions.ClearImage",
                                body: "Instructions.ClearImageBody",
                                image: Constants.ImageName.clearImage)
                makeInstruction(title: "Instructions.RemoveObstructions",
                                body: "Instructions.RemoveObstructionsBody",
                                image: Constants.ImageName.face)
            }
            VStack(spacing: 18) {
                SmileButton(title: "Instructions.Action", clicked: {

                })
                Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
            }.padding(.top, 80)
            Spacer()
        }
    }

    func makeInstruction(title: LocalizedStringKey, body: LocalizedStringKey, image: String) -> some View {
        return HStack(spacing: 16) {
            if let instructionImage = SmileIDResourcesHelper.image(image) {
                Image(uiImage: instructionImage)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(SmileIDResourcesHelper.localizedString(for: title.stringKey))
                    .font(SmileIdentity.theme.header4)
                    .foregroundColor(SmileIdentity.theme.accent)
                Text(SmileIDResourcesHelper.localizedString(for: body.stringKey))
                    .multilineTextAlignment(.leading)
                    .font(SmileIdentity.theme.header5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                    .lineSpacing(1.3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SmartSelfieInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartSelfieInstructionsView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                                      sessionId: UUID().uuidString,
                                                                      isEnroll: false,
                                                                      showAttribution: true),
                                    delegate: DummyDelegate())
            .environment(\.locale, Locale(identifier: "en"))

    }
}
