import SwiftUI

struct SelfieConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SelfieCaptureViewModel
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.GoodSelfie"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header2)
                    .foregroundColor(SmileIdentity.theme.accent)

                Text(SmileIDResourcesHelper.localizedString(for: "Confirmation.FaceClear"))
                    .multilineTextAlignment(.center)
                    .font(SmileIdentity.theme.header5)
                    .foregroundColor(SmileIdentity.theme.tertiary)
                    .lineSpacing(1.3)
            }
            VStack {
                Image(uiImage: UIImage(data: viewModel.selfieImage ?? Data()) ?? UIImage())
                    .cornerRadius(16)
                    .clipped()
            }

            VStack {
                SmileButton(style: .secondary,
                            title: "Confirmation.YesUse",
                            clicked: {
                    viewModel.processingState = .inProgress
                    viewModel.submit()

                })
                SmileButton(style: .secondary,
                            title: "Confirmation.Retake",
                            clicked: { viewModel.processingState = nil
                                        viewModel.resetCapture()
                })
            }.padding()
        }
        .padding(.top, 64)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
    }
}

struct ContentView: View {
    @State private var showModal = false

    var body: some View {
        ZStack {
            Button(action: {
                withAnimation {
                    showModal.toggle()
                }
            }) {
                Text("Show Modal")
            }
            ModalPresenter(isPresented: $showModal) {
                ErrorView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
