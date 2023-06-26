import SwiftUI

struct SelfieInstructionsFallbackView: View, SelfieInstructions {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel : SelfieCaptureViewModel
    private weak var selfieCaptureDelegate: SmartSelfieResultDelegate?
    @State private var goesToDetail: Bool = false

    init(viewModel: SelfieCaptureViewModel, delegate: SmartSelfieResultDelegate) {
        self.viewModel = viewModel
        self.selfieCaptureDelegate = delegate
    }

    // Only exists for preview so not accessible out of the file
    fileprivate init(viewModel: SelfieCaptureViewModel) {
        self.viewModel = viewModel
    }
    public var body: some View {
        NavigationView {
            VStack {
                if let processingState = viewModel.processingState, processingState == .endFlow {
                    let _ = DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ScrollView {
                    VStack {
                        Image(uiImage: SmileIDResourcesHelper.InstructionsHeaderIcon)
                            .padding(.bottom, 27)
                        VStack(spacing: 32) {
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
                    }
                }
                .navigationBarItems(leading: Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(uiImage: SmileIDResourcesHelper.Close)
                        .padding()
                })
                VStack(spacing: 18) {

                    NavigationLink(destination: SelfieCaptureView(viewModel: viewModel,
                                                                  delegate: selfieCaptureDelegate ??
                                                                  DummyDelegate()),
                                   isActive: $goesToDetail) { SmileButton(title: "Instructions.Action",
                                                                          clicked: {
                                       goesToDetail = true
                                   })}

                    // TO-DO: Enable after rebrand has been launched.

                    //                        if viewModel.showAttribution {
                    //                            Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                    //                        }

                }
            }
            .padding(EdgeInsets(top: 0,
                                leading: 24,
                                bottom: 24,
                                trailing: 24))
            .background(SmileID.theme.backgroundMain.edgesIgnoringSafeArea(.all))
        }
    }
}

struct SelfieInstructionsFallbackView_Previews: PreviewProvider {
    static var previews: some View {
        SelfieInstructionsFallbackView(viewModel: SelfieCaptureViewModel(userId: UUID().uuidString,
                                                                         jobId: UUID().uuidString,
                                                                         isEnroll: false,
                                                                         showAttribution: true))
    }
}


protocol SelfieInstructions {
//    associatedtype <#AssocType#>: View
//    func makeInstruction(title: LocalizedStringKey, body: LocalizedStringKey, image: String) -> <#AssocType#>
}

extension SelfieInstructions {
    func makeInstruction(title: LocalizedStringKey, body: LocalizedStringKey, image: String) -> some View {
        return HStack(spacing: 16) {
            if let instructionImage = SmileIDResourcesHelper.image(image) {
                Image(uiImage: instructionImage)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(SmileIDResourcesHelper.localizedString(for: title.stringKey))
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)
                Text(SmileIDResourcesHelper.localizedString(for: body.stringKey))
                    .multilineTextAlignment(.leading)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
