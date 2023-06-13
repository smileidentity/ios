import SwiftUI
import SmileID

struct EnterUserIDView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var userId: String
    @State private var goToAuth: Bool = false
    @ObservedObject var viewModel: UserIDViewModel

    var body: some View {
        NavigationView {
            if viewModel.shouldDismiss {
                let _ = DispatchQueue.main.async {
                     presentationMode.wrappedValue.dismiss()
                }
            }
            VStack(spacing: 5){
                Text("Please enter an enrolled User ID")
                    .font(SmileID.theme.header4)
                    .foregroundColor(SmileID.theme.onLight)
                VStack {
                    SmileTextField(field: $userId, placeholder: "User ID")
                        .multilineTextAlignment(.center)
                    NavigationLink(destination: SmileID.smartSelfieAuthenticationScreen(userId: userId, delegate: viewModel).navigationBarBackButtonHidden(true), isActive: $goToAuth ) {
                    }
                    SmileButton(title: "Continue", clicked: {
                        goToAuth = true
                    })
                    .padding()
                }
                Spacer()
            }
            .padding(.top, 50)
            .background(offWhite.edgesIgnoringSafeArea(.all))
            .navigationBarItems(leading: Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(uiImage: SmileIDResourcesHelper.Close)
                    .padding()
            })
        }
        .navigationBarBackButtonHidden()
    }
}

struct EnterUserIDView_Previews: PreviewProvider {
    static var previews: some View {
        EnterUserIDView(userId: "", viewModel: UserIDViewModel())
    }
}

class UserIDViewModel: ObservableObject, SmartSelfieResultDelegate {
    @Published var shouldDismiss = false

    func didSucceed(selfieImage: Data, livenessImages: [Data], jobStatusResponse: JobStatusResponse) {
        shouldDismiss = true
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "SelfieCaptureComplete"), object: ["Response": jobStatusResponse]))
    }

    func didError(error: Error) {
        shouldDismiss = true
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "SelfieCaptureError"), object: ["Error": error]))
    }


}
