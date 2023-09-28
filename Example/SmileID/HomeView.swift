import SmileID
import SwiftUI

@available(iOS 14.0, *)
struct HomeView: View {
    var userID = ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    @ObservedObject var viewModel = HomeViewModel()
    @ObservedObject var router = Router<NavigationDestination>()
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Test Our Products")
                    .font(SmileID.theme.header2)
                    .foregroundColor(.black)
                HStack(spacing: 16) {
                    Button(
                        action: viewModel.handleSmartSelfieEnrolmentTap,
                        label: {
                            ProductCell(
                                productImage: "userauth",
                                productName: "SmartSelfie™ Enrollment"
                            )
                        })
                        .sheet(isPresented: $viewModel.presentSmartSelfieEnrollment,
                               content: {
                                   SmileID.smartSelfieEnrollmentScreen(
                                       userId: generateUserId(),
                                       allowAgentMode: true,
                                       delegate: viewModel
                                   )
                               })
                    Button(action: viewModel.handleSmartSelfieAuthTap,
                           label: {
                               ProductCell(
                                   productImage: "userauth",
                                   productName: "SmartSelfie™ Authentication"
                               )
                           })
                        .sheet(isPresented: $viewModel.presentSmartSelfieAuth, content: {
                            EnterUserIDView(
                                userId: viewModel.returnedUserID,
                                viewModel: UserIDViewModel()
                            )
                        })
                }
                HStack(spacing: 15) {
                    GeometryReader { geo in
                        Button(
                            action: viewModel.handleDocumentVerificationTap,
                            label: {
                                ProductCell(
                                    productImage: "document",
                                    productName: "Document Verification"
                                )
                            }
                        )
                            .fullScreenCover(
                                isPresented: $viewModel.presentDocumentVerification,
                                content: {
                                    let _ = router.push(
                                        .countrySelectorScreen(homeVieModel: viewModel),
                                        animated: false
                                    )
                                    NavigationControllerHost(
                                        navTitle: "",
                                        navHidden: true,
                                        router: router,
                                        routeMap: ViewFactory().makeView(_:)
                                    ).environmentObject(router)
                                })
                            .frame(width: (geo.size.width / 2) - 7.5)
                    }
                }
                Spacer()
                let partner = "Partner \(SmileID.configuration.partnerId)"
                let version = "Version \(SmileID.version)"
                let build = "Build \(build ?? "")"
                Text("\(partner) - \(version) - \(build)")
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
}

@available(iOS 14.0, *)
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
                    backgroundColor
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
