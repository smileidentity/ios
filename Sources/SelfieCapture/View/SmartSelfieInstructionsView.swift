import SwiftUI

public struct SmartSelfieInstructionsView: View {
    @Environment(\.presentationMode) var presentationMode
    private var viewModel : SelfieCaptureViewModel
    private weak var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.selfieCaptureDelegate = delegate
    }
    
    //Only exists for preview so not accessible out of the file
    fileprivate init(viewModel: SelfieCaptureViewModel) {
        self.viewModel = viewModel
    }
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderIcon)
                        .padding(.bottom, 27)
                    VStack(spacing: 32) {
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Header"))
                            .multilineTextAlignment(.center)
                            .font(SmileIdentity.theme.header1)
                            .foregroundColor(SmileIdentity.theme.accent)
                            .lineSpacing(0.98)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(SmileIDResourcesHelper.localizedString(for: "Instructions.Callout"))
                            .multilineTextAlignment(.center)
                            .font(SmileIdentity.theme.header5)
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

                        NavigationLink(destination: SelfieCaptureView(viewModel: viewModel,
                                                                      delegate: selfieCaptureDelegate ??
                                                                      DummyDelegate()),
                                       isActive: $goesToDetail) { SmileButton(title: "Instructions.Action",
                                                                              clicked: {
                                           goesToDetail = true
                                       })}
                        if viewModel.showAttribution {
                            Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                        }
                    }.padding(.top, 80)
                }
                .padding(EdgeInsets(top: 40,
                                    leading: 24,
                                    bottom: 0,
                                    trailing: 24))
            }
            .navigationBarItems(leading: Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(uiImage: SmileIDResourcesHelper.Close)
                    .padding()
            })
            .background(SmileIdentity.theme.backgroundMain.edgesIgnoringSafeArea(.all))
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
                                                                      showAttribution: true))
        .environment(\.locale, Locale(identifier: "en"))

    }
}
