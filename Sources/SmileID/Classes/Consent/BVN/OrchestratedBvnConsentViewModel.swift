import Combine
import SwiftUI

internal enum BvnConsentScreen {
    case consentScreen
    case bvnInputScreen
    case chooseOtpDeliveryScreen
    case verifyOtpScreen
}

class OrchestratedBvnConsentViewModel: ObservableObject {
    // MARK: - Input Properties
    let userId: String

    // MARK: - UI Properties
    // todo: change back to consentScreen as first screen
    @Published @MainActor private(set) var currentScreen: BvnConsentScreen = .bvnInputScreen
    @Published @MainActor private(set) var isBvnValid = false
    @Published @MainActor private(set) var isBvnOtpValid = false
    @Published @MainActor private(set) var showLoading = false
    @Published @MainActor private(set) var showError = false
    @Published @MainActor private(set) var showSuccess = false
    @Published @MainActor private(set) var bvn: String = ""
    @Published @MainActor private(set) var otp: String = ""
    // @Published @MainActor private(set) var bvnVerificationModes: [BvnOtpVerificationMode] = []
    // @Published @MainActor
    // private(set) var selectedBvnOtpVerificationMode: BvnOtpVerificationMode?

    // MARK: - Other Properties
    private var sessionId: String?
    private var authResponsePublisher: AnyPublisher<AuthenticationResponse, Error>?
    private var cancellables = Set<AnyCancellable>()

    init(userId: String) {
        self.userId = userId

        let authRequest = AuthenticationRequest(
            jobType: JobType.bvn,
            enrollment: false,
            userId: userId
        )
        let (authResponsePublisher, test): (AnyPublisher<AuthenticationResponse, Error>, Never) = {
            let a = SmileID.api.authenticate(request: authRequest))
            return (a.eraseToAnyPublisher(), a.connect())
        }()
    }

    @MainActor
    func onConsentGranted() {
        currentScreen = .bvnInputScreen
    }

    // TODO: length validations

    // @MainActor
    // func updateMode(input: BvnOtpVerificationMode) {
    //     selectedBvnOtpVerificationMode = input
    //     otp = ""
    // }

    @MainActor
    func selectContactMethod() {
        currentScreen = .chooseOtpDeliveryScreen
        showError = false
    }

    @MainActor
    func submitUserBvn(bvn: String) {
        if showLoading {
            print("A request is already in progress")
            return
        }
        if bvn.count != 11 {
            showError = true
            return
        }
        self.bvn = bvn
        showLoading = true
        SmileID.api.requestBvnTotpMode(request: BvnTotpRequest(
            idNumber: bvn,
            signature: <#T##String##Swift.String#>
        ))
    }

    @MainActor
    func requestBvnOtp() {
        if showLoading {
            print("A request is already in progress")
            return
        }
        showLoading = true
        // TODO: request bvn network request
    }

    @MainActor
    func submitBvnOtp() {
        // TODO: OTP input length validation
        if showLoading {
            print("A request is already in progress")
            return
        }
        showLoading = true
        // TODO: submit bvn otp network request
    }
}
