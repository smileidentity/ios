import SmileID
import SwiftUI

struct HomeView: View {
    let version = SmileID.version
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    @ObservedObject var viewModel: HomeViewModel

    @State private var selectedProduct: SmileIDProduct? = nil

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
                        userId: viewModel.newUserId,
                        jobId: viewModel.newJobId,
                        allowAgentMode: true,
                        delegate: SmartSelfieEnrollmentDelegate(
                            userId: viewModel.newUserId,
                            onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                            onError: viewModel.didError
                        )
                    )
                case .smartSelfieAuthentication:
                    SmartSelfieAuthWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        delegate: viewModel
                    )
                case .enhancedSmartSelfieEnrollment:
                    SmileID.smartSelfieEnrollmentScreenEnhanced(
                        userId: viewModel.newUserId,
                        delegate: SmartSelfieEnrollmentDelegate(
                            userId: viewModel.newUserId,
                            onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                            onError: viewModel.didError
                        )
                    )
                case .enhancedSmartSelfieAuthentication:
                    SmartSelfieAuthEnhancedWithUserIdEntry(
                        initialUserId: viewModel.lastSelfieEnrollmentUserId ?? "",
                        delegate: viewModel
                    )
                case .enhancedKYC:
                    EnhancedKycWithIdInputScreen(
                        delegate: viewModel,
                        viewModel: EnhancedKycWithIdInputScreenViewModel(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId
                        )
                    )
                case .biometricKYC:
                    BiometricKycWithIdInputScreen(
                        delegate: viewModel,
                        viewModel: BiometricKycWithIdInputScreenViewModel(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId
                        )
                    )
                case .documentVerification:
                    NavigationView {
                        DocumentVerificationWithSelector(
                            userId: viewModel.newUserId,
                            jobId: viewModel.newJobId,
                            delegate: viewModel
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    selectedProduct = nil
                                } label: {
                                    Text(SmileIDResourcesHelper.localizedString(for: "Action.Cancel"))
                                        .foregroundColor(SmileID.theme.accent)
                                }
                            }
                        }
                    }
                case .enhancedDocumentVerification:
                    EnhancedDocumentVerificationWithSelector(
                        userId: viewModel.newUserId,
                        jobId: viewModel.newJobId,
                        delegate: viewModel
                    )
                }
            }
        }
    }
}

// We need to define a separate proxy delegate because it's the same protocol for both Enrollment
// and Authentication. However, since the result is still processing, the result parameter is not
// yet populated (which is what contains the jobType). On Enroll, we need to perform a different
// action (namely, save userId to clipboard)
struct SmartSelfieEnrollmentDelegate: SmartSelfieResultDelegate {
    let userId: String
    let onEnrollmentSuccess: (
        _ userId: String,
        _ selfieFile: URL,
        _ livenessImages: [URL],
        _ apiResponse: SmartSelfieResponse?
    ) -> Void
    let onError: (Error) -> Void

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
    let delegate: SmartSelfieResultDelegate

    @State private var userId: String?

    var body: some View {
        if let userId {
            SmileID.smartSelfieAuthenticationScreen(
                userId: userId,
                allowAgentMode: true,
                delegate: delegate
            )
        } else {
            EnterUserIDView(initialUserId: initialUserId) { userId in
                self.userId = userId
            }
        }
    }
}

private struct SmartSelfieAuthEnhancedWithUserIdEntry: View {
    let initialUserId: String
    let delegate: SmartSelfieResultDelegate

    @State private var userId: String?

    var body: some View {
        if let userId {
            SmileID.smartSelfieAuthenticationScreenEnhanced(
                userId: userId,
                delegate: delegate
            )
        } else {
            EnterUserIDView(initialUserId: initialUserId) { userId in
                self.userId = userId
            }
        }
    }
}

/// A view that displays a grid of items in a vertical layout. It first fills up all items in the
/// first row before moving on to the next row. If the number of items is not a multiple of the
/// number of columns, the last row is filled from left to right with the remaining items.
private struct MyVerticalGrid: View {
    let maxColumns: Int
    let items: [AnyView]

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    let numRows = (items.count + maxColumns - 1) / maxColumns
                    ForEach(0 ..< numRows, id: \.self) { rowIndex in
                        HStack(spacing: 16) {
                            ForEach(0 ..< maxColumns, id: \.self) { columnIndex in
                                let itemIndex = rowIndex * maxColumns + columnIndex
                                let width = geo.size.width / CGFloat(maxColumns)
                                if itemIndex < items.count {
                                    // Use the item at the calculated index
                                    items[itemIndex].frame(width: width)
                                } else {
                                    Spacer().frame(width: width)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
