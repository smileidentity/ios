import SmileID
import SwiftUI

struct HomeView: View {
    var userID = ""
    @ObservedObject var viewModel = HomeViewModel()
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Test Our Products")
                    .font(SmileID.theme.header2)
                    .foregroundColor(.black)
                HStack(spacing: 15) {
                    Button(action: { self.viewModel.handleSmartSelfieEnrolmentTap() }) {
                        ProductCell(productImage: "userauth", productName: "SmartSelfie™ \nEnrollment")
                    }

                    .sheet(isPresented: $viewModel.presentSmartSelfieEnrollment,
                           content: { SmileID.smartSelfieEnrollmentScreen(userId: viewModel.generateUserID(),
                                                                          delegate: viewModel) })
                    Button(action: { self.viewModel.handleSmartSelfieAuthTap() }) {
                        ProductCell(productImage: "userauth", productName: "SmartSelfie™ \nAuthentication")
                    }
                    .sheet(isPresented: $viewModel.presentSmartSelfieAuth, content: {
                        EnterUserIDView(userId: viewModel.returnedUserID, viewModel: UserIDViewModel())
                    })
                }
                HStack(spacing: 15) {
                    Button(action: { self.viewModel.handleDocumentVerificationTap() }) {
                        ProductCell(productImage: "document", productName: "Document \nVerification")
                    }
                    .sheet(isPresented: $viewModel.presentDocumentVerification,
                           content: { SmileID.documentVerificationScreen(userId: viewModel.generateUserID(),
                                                                         delegate: viewModel) })
                }
                Spacer()
                Text("Partner \(SmileID.configuration.partnerId) - Version \(VersionNames().version)")
                    .font(SmileID.theme.body)
                    .foregroundColor(SmileID.theme.onLight)
            }
            .toast(isPresented: $viewModel.showToast) {
                Text(viewModel.toastMessage)
                    .font(SmileID.theme.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationBarTitle(Text("Smile ID"), displayMode: .inline)
            .navigationBarItems(trailing: ToggleButton())
            .background(offWhite.edgesIgnoringSafeArea(.all))
        }
    }

    mutating func generateUUID() {
        userID = UUID().uuidString
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct NavigationBarModifier: ViewModifier {
    var backgroundColor: Color = .clear

    init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = .clear
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                GeometryReader { geometry in
                    self.backgroundColor
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

extension View {
    func navigationBarColor(_ backgroundColor: Color) -> some View {
        modifier(NavigationBarModifier(backgroundColor: backgroundColor))
    }
}
