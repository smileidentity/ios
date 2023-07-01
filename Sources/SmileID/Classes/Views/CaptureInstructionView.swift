import SwiftUI

enum CaptureType {
    case selfie
    case document
}

public struct CaptureInstruction {
    var title: String
    var instruction: String
    var image: String
}

// this should be reused with the selfie and document capture and can be extended in terms of instructions
public struct CaptureInstructionView<TargetView: View>: View {
    @Environment(\.presentationMode) var presentationMode
    private var image: UIImage
    private var title: String
    private var callOut: String
    private var instructions: [CaptureInstruction]
    private var detailView: TargetView
    private var captureType: CaptureType
    private var showAttribution: Bool
    @State private var goesToDetail: Bool = false
    init(image: UIImage,
         title: String,
         callOut: String,
         instructions: [CaptureInstruction],
         captureType: CaptureType,
         detailView: TargetView,
         showAttribution: Bool) {
        self.image = image
        self.title = title
        self.callOut = callOut
        self.instructions = instructions
        self.detailView = detailView
        self.captureType = captureType
        self.showAttribution = showAttribution
    }

    public var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {
                        Image(uiImage: image)
                            .padding(.bottom, 27)
                        VStack(spacing: 16) {
                            Text(title)
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.header1)
                                .foregroundColor(SmileID.theme.accent)
                                .lineSpacing(0.98)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(callOut)
                                .multilineTextAlignment(.center)
                                .font(SmileID.theme.header5)
                                .foregroundColor(SmileID.theme.tertiary)
                                .lineSpacing(1.3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 20)
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(instructions, id: \.title) { i in
                                makeInstruction(title: i.title,
                                                body: i.instruction,
                                                image: i.image)
                            }
                        }
                    }
                }
                .navigationBarItems(leading: Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(uiImage: SmileIDResourcesHelper.Close)
                        .padding()
                })
                VStack(spacing: 5) {
                    NavigationLink(destination: detailView,
                                   isActive: $goesToDetail) {
                        SmileButton(title: captureType == .document ?
                                    "Action.TakePhoto" : "Instructions.Action",
                                    clicked: { goesToDetail = true })
                    }
                    if captureType == .document {
                        NavigationLink(destination: detailView,
                                       isActive: $goesToDetail)
                        {
                            SmileButton(style: .alternate,
                                        title: "Action.UploadPhoto",
                                        clicked: { goesToDetail = true })
                        }
                    }

                    if showAttribution {
                        Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                            .padding()
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
                NavigationLink(destination: detailView,
                               isActive: $goesToDetail) {
                    SmileButton(title: "Instructions.Action", clicked: { goesToDetail = true })
                }
            }
        }
        .padding(EdgeInsets(top: 0,
                            leading: 24,
                            bottom: 24,
                            trailing: 24))
        .background(SmileID.theme.backgroundMain.edgesIgnoringSafeArea(.all))
    }

    func makeInstruction(title: String, body: String, image: String) -> some View {
        return HStack(spacing: 16) {
            if let instructionImage = SmileIDResourcesHelper.image(image) {
                Image(uiImage: instructionImage)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(SmileIDResourcesHelper.localizedString(for: title))
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.accent)
                Text(SmileIDResourcesHelper.localizedString(for: body))
                    .multilineTextAlignment(.leading)
                    .font(SmileID.theme.header5)
                    .foregroundColor(SmileID.theme.tertiary)
                    .lineSpacing(1.3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
