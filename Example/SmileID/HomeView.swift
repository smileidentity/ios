import SmileID
import SwiftUI

struct HomeView: View {
    let partner = SmileID.configuration.partnerId
    let version = SmileID.version
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    @State private var smartSelfieEnrollmentUserId: String = ""
    @ObservedObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Test Our Products")
                    .font(SmileID.theme.header2)
                    .foregroundColor(.black)

                MyVerticalGrid(
                    maxColumns: 2,
                    items: [
                        ProductCell(
                            image: "userauth",
                            name: "SmartSelfie™ Enrollment",
                            onClick: { smartSelfieEnrollmentUserId = generateUserId() },
                            content: {
                                SmileID.smartSelfieEnrollmentScreen(
                                    userId: smartSelfieEnrollmentUserId,
                                    allowAgentMode: true,
                                    delegate: SmartSelfieEnrollmentDelegate(
                                        userId: smartSelfieEnrollmentUserId,
                                        onEnrollmentSuccess: viewModel.onSmartSelfieEnrollment,
                                        onError: viewModel.didError
                                    )
                                )
                            }
                        ),
                        ProductCell(
                            image: "userauth",
                            name: "SmartSelfie™ Authentication",
                            content: {
                                SmartSelfieAuthWithUserIdEntry(
                                    initialUserId: smartSelfieEnrollmentUserId,
                                    delegate: viewModel
                                )
                            }
                        ),
                        ProductCell(
                            image: "document",
                            name: "\nDocument Verification",
                            content: { DocumentVerificationWithSelector(delegate: viewModel) }
                        ),
                        ProductCell(
                            image: "document",
                            name: "Enhanced Document Verification",
                            content: {
                                EnhancedDocumentVerificationWithSelector(delegate: viewModel)
                            }
                        ),
                        ProductCell(
                            image: "biometric",
                            name: "Biometric KYC",
                            content: {
                                SmileID.biometricKycScreen(
                                    partnerIcon: UIImage(named: "SmileLogo")!,
                                    partnerName: "Smile ID",
                                    productName: "ID",
                                    partnerPrivacyPolicy: URL(string: "https://usesmileid.com")!,
                                    delegate: viewModel
                                )
                            }
                        )
                    ].map { AnyView($0) }
                )

                Text("Partner \(partner) - Version \(version) - Build \(build)")
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
                .background(SmileID.theme.backgroundLight.edgesIgnoringSafeArea(.all))
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
        _ jobStatusResponse: SmartSelfieJobStatusResponse
    ) -> Void
    let onError: (Error) -> Void

    func didSucceed(
        selfieImage: URL,
        livenessImages: [URL],
        jobStatusResponse: SmartSelfieJobStatusResponse
    ) {
        onEnrollmentSuccess(userId, selfieImage, livenessImages, jobStatusResponse)
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
        if let userId = userId {
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

private struct DocumentVerificationWithSelector: View {
    @State private var countryCode: String?
    @State private var documentType: String?
    @State private var captureBothSides: Bool?
    let delegate: DocumentVerificationResultDelegate

    var body: some View {
        if let countryCode = countryCode,
           let documentType = documentType,
           let captureBothSides = captureBothSides {
            SmileID.documentVerificationScreen(
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                allowGalleryUpload: true,
                delegate: delegate
            )
        } else {
            DocumentVerificationIdTypeSelector(
                jobType: .documentVerification
            ) { countryCode, documentType, captureBothSides in
                self.countryCode = countryCode
                self.documentType = documentType
                self.captureBothSides = captureBothSides
            }
        }
    }
}

private struct EnhancedDocumentVerificationWithSelector: View {
    @State private var countryCode: String?
    @State private var documentType: String?
    @State private var captureBothSides: Bool?
    let delegate: EnhancedDocumentVerificationResultDelegate

    var body: some View {
        if let countryCode = countryCode,
           let documentType = documentType,
           let captureBothSides = captureBothSides {
            SmileID.enhancedDocumentVerificationScreen(
                countryCode: countryCode,
                documentType: documentType,
                captureBothSides: captureBothSides,
                allowGalleryUpload: true,
                delegate: delegate
            )
        } else {
            DocumentVerificationIdTypeSelector(
                jobType: .enhancedDocumentVerification
            ) { countryCode, documentType, captureBothSides in
                self.countryCode = countryCode
                self.documentType = documentType
                self.captureBothSides = captureBothSides
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
                    ForEach(0..<numRows) { rowIndex in
                        HStack(spacing: 16) {
                            ForEach(0..<maxColumns) { columnIndex in
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

@available(iOS 14.0, *)
private struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = SmileID.initialize(
            config: Config(
                partnerId: "",
                authToken: "",
                prodUrl: "",
                testUrl: "",
                prodLambdaUrl: "",
                testLambdaUrl: ""
            ),
            useSandbox: true
        )
        HomeView()
    }
}
