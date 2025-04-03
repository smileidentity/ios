import SmileID
import SwiftUI

struct HomeView: View {
    let version = SmileID.version
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    @ObservedObject var viewModel: HomeViewModel

    init(config: Config) {
        self.viewModel = HomeViewModel(config: config)
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Test Our Products")
                    .font(SmileID.theme.header2)
                    .foregroundColor(.black)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(SmileIDProduct.allCases, id: \.self) { product in
                            Button {
                                viewModel.onProductClicked()
                                viewModel.selectedProduct = product
                            } label: {
                                ProductCell(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Partner \(viewModel.partnerId) - Version \(version) - Build \(build)")
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
            .navigationBarItems(trailing: SmileEnvironmentToggleButton())
            .background(SmileID.theme.backgroundLight.ignoresSafeArea())
            .fullScreenCover(item: $viewModel.selectedProduct) { product in
                switch product {
                case .smartSelfieEnrollment:
                    SmileID.smartSelfieEnrollmentScreen(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            allowAgentMode: true
                        ),
                        delegate: SmartSelfieEnrollmentDelegate(
                            userId: viewModel.newUserId,
                            onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                            onError: viewModel.didError,
                            onCancel: viewModel.didCancel
                        )
                    )
                case .smartSelfieAuthentication:
                    SmartSelfieAuthWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        delegate: viewModel,
                        onDismiss: { viewModel.selectedProduct = nil }
                    )
                case .enhancedSmartSelfieEnrollment:
                    SmileID.smartSelfieEnrollmentScreenEnhanced(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: viewModel.newUserId
                        ),
                        delegate: SmartSelfieEnrollmentDelegate(
                            userId: viewModel.newUserId,
                            onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                            onError: viewModel.didError,
                            onCancel: viewModel.didCancel
                        )
                    )
                case .enhancedSmartSelfieAuthentication:
                    SmartSelfieAuthWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        useStrictMode: true,
                        delegate: viewModel,
                        onDismiss: { viewModel.selectedProduct = nil }
                    )
                case .enhancedKYC:
                    CancellableNavigationView {
                        EnhancedKycWithIdInputScreen(
                            delegate: viewModel,
                            viewModel: EnhancedKycWithIdInputScreenViewModel(
                                userId: viewModel.newUserId,
                                jobId: viewModel.newJobId
                            )
                        )
                    } onCancel: {
                        viewModel.selectedProduct = nil
                    }
                case .biometricKYC:
                    CancellableNavigationView {
                        BiometricKycWithIdInputScreen(
                            viewModel: BiometricKycWithIdInputScreenViewModel(
                                userId: viewModel.newUserId,
                                jobId: viewModel.newJobId,
                                didFinish: { didSubmit, error in
                                    viewModel.handleBiometricKYCCompleted(didSubmit, error)
                                }
                            )
                        )
                    } onCancel: {
                        viewModel.selectedProduct = nil
                    }
                case .documentVerification:
                    CancellableNavigationView {
                        DocumentVerificationWithSelector(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            delegate: viewModel
                        )
                    } onCancel: {
                        viewModel.selectedProduct = nil
                    }
                case .enhancedDocumentVerification:
                    CancellableNavigationView {
                        EnhancedDocumentVerificationWithSelector(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            delegate: viewModel
                        )
                    } onCancel: {
                        viewModel.selectedProduct = nil
                    }
                }
            }
        }
    }
}

private struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = SmileID.initialize(
            config: Config(
                partnerId: "",
                authToken: "",
                prodLambdaUrl: "",
                testLambdaUrl: ""
            ),
            useSandbox: true
        )
        HomeView(config: Config(
            partnerId: "1000",
            authToken: "",
            prodLambdaUrl: "",
            testLambdaUrl: ""
        ))
    }
}
