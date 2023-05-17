import SwiftUI

struct SelfieConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    var image: UIImage
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
                Image(uiImage: image)
                    .cornerRadius(16)
                    .clipped()
            }

            VStack {
                SmileButton(style: .secondary,
                            title: "Confirmation.YesUse",
                            clicked: {})
                SmileButton(style: .secondary,
                            title: "Confirmation.Retake",
                            clicked: {presentationMode.wrappedValue.dismiss()})
            }
        }
        .padding()
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
                SelfieConfirmationView(image: UIImage())
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
