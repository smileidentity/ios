import SwiftUI

enum CaptureType: Equatable {
    case selfie
    case document(Position)

    enum Position {
        case front
        case back
    }
}

public struct CaptureInstruction {
    var title: String
    var instruction: String
    var image: String
}

// this should be reused with the selfie and document capture and can be extended in terms of instructions
public struct CaptureInstructionView<TargetView: View>: View {
    private var image: UIImage
    private var title: String
    private var callOut: String
    private var buttonTitle: LocalizedStringKey
    private var instructions: [CaptureInstruction]
    private var destination: NavigationDestination
    private var secondaryDestination: NavigationDestination?
    private var captureType: CaptureType
    private var showAttribution: Bool
    private var allowGalleryUpload: Bool
    @EnvironmentObject var router: Router<NavigationDestination>
    @State private var goesToDetail: Bool = false
    init(image: UIImage,
         title: String,
         callOut: String,
         buttonTitle: LocalizedStringKey,
         instructions: [CaptureInstruction],
         captureType: CaptureType,
         destination: NavigationDestination,
         secondaryDestination: NavigationDestination? = nil,
         showAttribution: Bool,
         allowGalleryUpload: Bool = false) {
        self.image = image
        self.title = title
        self.callOut = callOut
        self.buttonTitle = buttonTitle
        self.instructions = instructions
        self.destination = destination
        self.secondaryDestination = secondaryDestination
        self.captureType = captureType
        self.showAttribution = showAttribution
        self.allowGalleryUpload = allowGalleryUpload
    }

    public var body: some View {
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
                        ForEach(instructions, id: \.title) { instruction in
                            makeInstruction(title: instruction.title,
                                            body: instruction.instruction,
                                            image: instruction.image)
                        }
                    }
                }
            }
            VStack(spacing: 5) {
                SmileButton(title: buttonTitle,
                            clicked: {
                    router.push(destination)
                            })
                if allowGalleryUpload {
                    SmileButton(style: .alternate, title:
                                    "Action.UploadPhoto",
                                clicked: {
                        if let secondaryDestination = secondaryDestination {
                            router.present(secondaryDestination)
                        }
                    })
                }

                if showAttribution {
                    Image(uiImage: SmileIDResourcesHelper.SmileEmblem)
                        .padding()
                }
            }
        }.padding(EdgeInsets(top: 0,
                             leading: 24,
                             bottom: 24,
                             trailing: 24))
            .background(SmileID.theme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
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
