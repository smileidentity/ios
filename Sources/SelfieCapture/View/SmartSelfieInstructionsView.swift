import SwiftUI

struct SmartSelfieInstructionsView: View {
    var body: some View {
        VStack {
            Image(Constants.ImageName.instructionsHeader, bundle: .module)
                .padding(.bottom, 27)
            VStack(spacing: 32) {
                Text("Instructions.Header", bundle: .module)
                    .multilineTextAlignment(.center)
                    .font(.h1)
                    .foregroundColor(.digitalBlue)
                    .lineSpacing(0.98)
                Text("Instructions.Callout", bundle: .module)
                    .multilineTextAlignment(.center)
                    .font(.h5)
                    .foregroundColor(.tertiaryA)
                    .lineSpacing(1.3)
            }
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
            .padding(.top, 47)

            VStack(spacing: 18) {
                SmileButton(title: "Instructions.Action", clicked: {

                })
                Image(Constants.ImageName.smileEmblem, bundle: .module)
            }.padding(.top, 50)

        }
        .padding(EdgeInsets(top: 50,
                            leading: 24,
                            bottom: 0,
                            trailing: 24))
    }

    func makeInstruction(title: LocalizedStringKey, body: LocalizedStringKey, image: String) -> some View {
        return HStack(spacing: 16) {
            Image(image, bundle: .module)
            VStack(alignment: .leading, spacing: 7) {
                Text(title, bundle: .module)
                    .font(.h4)
                    .foregroundColor(.digitalBlue)
                Text(body, bundle: .module)
                    .font(.h5)
                    .foregroundColor(.tertiaryA)
                    .lineSpacing(1.3)
            }
        }
    }
}

struct SmartSelfieInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartSelfieInstructionsView()
            .environment(\.locale, Locale(identifier: "en"))
            .loadCustomFonts()
    }
}
