import SwiftUI

public struct SmartSelfieInstructionsView: View {

    private var viewModel : SelfieCaptureViewModel
    private weak var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.selfieCaptureDelegate = delegate
    }
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Image(Constants.ImageName.instructionsHeader, bundle: .module)
                        .padding(.bottom, 27)
                    VStack(spacing: 32) {
                        Text("Instructions.Header", bundle: .module)
                            .multilineTextAlignment(.center)
                            .font(SmileIdentity.theme.h1)
                            .foregroundColor(SmileIdentity.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Instructions.Callout", bundle: .module)
                            .multilineTextAlignment(.center)
                            .font(SmileIdentity.theme.h5)
                            .foregroundColor(SmileIdentity.theme.tertiary)
                            .lineSpacing(1.3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 20)
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

                        NavigationLink(destination: SelfieCaptureView(viewModel: viewModel, delegate: selfieCaptureDelegate ?? DummyDelegate()),
                                       isActive: $goesToDetail) { SmileButton(title: "Instructions.Action",
                                                                              clicked: {
                                           goesToDetail = true
                                       })}
                        Image(Constants.ImageName.smileEmblem, bundle: .module)
                    }.padding(.top, 80)
                }
                .padding(EdgeInsets(top: 40,
                                    leading: 24,
                                    bottom: 0,
                                    trailing: 24))
            }
        }
    }

    func makeInstruction(title: LocalizedStringKey, body: LocalizedStringKey, image: String) -> some View {
        return HStack(spacing: 16) {
            Image(image, bundle: .module)
            VStack(alignment: .leading, spacing: 7) {
                Text(title, bundle: .module)
                    .font(SmileIdentity.theme.h4)
                    .foregroundColor(SmileIdentity.theme.accent)
                Text(body, bundle: .module)
                    .multilineTextAlignment(.leading)
                    .font(SmileIdentity.theme.h5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                    .lineSpacing(1.3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SmartSelfieInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartSelfieInstructionsView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString, sessionId: UUID().uuidString, isEnroll: false), delegate: DummyDelegate())
            .environment(\.locale, Locale(identifier: "en"))
            .loadCustomFonts()
    }
}
