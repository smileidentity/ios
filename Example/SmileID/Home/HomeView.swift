import SmileID
import SwiftUI

struct HomeView: View {
    let version = SmileID.version
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    @ObservedObject var viewModel: HomeViewModel

    @State private var selectedProduct: SmileIDProduct?

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
                                selectedProduct = product
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
            .fullScreenCover(item: $selectedProduct) { product in
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
                            onError: viewModel.didError
                        ),
                        onDismiss: { selectedProduct = nil }
                    )
                case .smartSelfieAuthentication:
                    SmartSelfieAuthWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        delegate: viewModel,
                        onDismiss: { selectedProduct = nil }
                    )
                case .enhancedSmartSelfieEnrollment:
                    SmileID.smartSelfieEnrollmentScreenEnhanced(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: viewModel.newUserId
                        ),
                        delegate: SmartSelfieEnrollmentDelegate(
                            userId: viewModel.newUserId,
                            onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                            onError: viewModel.didError
                        ),
                        onDismiss: { selectedProduct = nil }
                    )
                case .enhancedSmartSelfieAuthentication:
                    SmartSelfieAuthWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        useStrictMode: true,
                        delegate: viewModel,
                        onDismiss: { selectedProduct = nil }
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
                        selectedProduct = nil
                    }
                case .biometricKYC:
                    CancellableNavigationView {
                        BiometricKycWithIdInputScreen(
                            delegate: viewModel,
                            viewModel: BiometricKycWithIdInputScreenViewModel(
                                userId: viewModel.newUserId,
                                jobId: viewModel.newJobId
                            )
                        )
                    } onCancel: {
                        selectedProduct = nil
                    }
                case .documentVerification:
                    CancellableNavigationView {
                        DocumentVerificationWithSelector(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            delegate: viewModel
                        )
                    } onCancel: {
                        selectedProduct = nil
                    }
                case .enhancedDocumentVerification:
                    CancellableNavigationView {
                        EnhancedDocumentVerificationWithSelector(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            delegate: viewModel
                        )
                    } onCancel: {
                        selectedProduct = nil
                    }
                }
            }
        }
    }
}

// We need to define a separate proxy delegate because it's the same protocol for both Enrollment
// and Authentication. However, since the result is still processing, the result parameter is not
// yet populated (which is what contains the jobType). On Enroll, we need to perform a different
// action (namely, save userId to clipboard)
class SmartSelfieEnrollmentDelegate: SmartSelfieResultDelegate {
    let userId: String
    let onEnrollmentSuccess: (
        _ userId: String,
        _ selfieFile: URL,
        _ livenessImages: [URL],
        _ apiResponse: SmartSelfieResponse?
    ) -> Void
    let onError: (Error) -> Void

    init(
        userId: String,
        onEnrollmentSuccess: @escaping (
            _: String,
            _: URL,
            _: [URL],
            _: SmartSelfieResponse?
        ) -> Void,
        onError: @escaping (
            Error
        ) -> Void
    ) {
        self.userId = userId
        self.onEnrollmentSuccess = onEnrollmentSuccess
        self.onError = onError
    }

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        apiResponse: SmartSelfieResponse?
    ) {
        onEnrollmentSuccess(userId, selfieImage, livenessImages, apiResponse)
    }

    func didError(error: Error) {
        onError(error)
    }
}

private struct SmartSelfieAuthWithUserIdEntry: View {
    let initialUserId: String
    let useStrictMode: Bool
    let delegate: SmartSelfieResultDelegate
    let onDismiss: (() -> Void)

    @State private var userId: String?

    init(
        initialUserId: String,
        useStrictMode: Bool = false,
        delegate: SmartSelfieResultDelegate,
        onDismiss: @escaping () -> Void
    ) {
        self.initialUserId = initialUserId
        self.delegate = delegate
        self.useStrictMode = useStrictMode
        self.onDismiss = onDismiss
    }

    var body: some View {
        if let userId {
            ZStack {
                if useStrictMode {
                    SmileID.smartSelfieAuthenticationScreenEnhanced(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: userId,
                            isEnroll: false
                        ),
                        delegate: delegate
                    )
                } else {
                    SmileID.smartSelfieAuthenticationScreen(
                        config: OrchestratedSelfieCaptureConfig(
                            userId: userId,
                            isEnroll: false,
                            allowAgentMode: true
                        ),
                        delegate: delegate,
                        onDismiss: onDismiss
                    )
                }
            }
            .transition(.move(edge: .trailing))
        } else {
            CancellableNavigationView {
                EnterUserIDView(initialUserId: initialUserId) { userId in
                    withAnimation {
                        self.userId = userId
                    }
                }
            } onCancel: {
                onDismiss()
            }
            .transition(.move(edge: .leading))
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
