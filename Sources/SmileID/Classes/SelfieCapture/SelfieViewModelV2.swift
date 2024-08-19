import ARKit
import Combine
import Foundation


public class SelfieViewModelV2: ObservableObject {

    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let useStrictMode: Bool
    private let faceDetector = FaceDetector()

    var cameraManager = CameraManager(orientation: .portrait)

    private var subscribers = Set<AnyCancellable>()

    // UI Properties
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"

    public init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String],
        useStrictMode: Bool
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        self.useStrictMode = useStrictMode

        cameraManager.$status
            .receive(on: DispatchQueue.main)
            .filter { $0 == .unauthorized }
            .map { _ in AlertState.cameraUnauthorized }
            .sink { alert in self.unauthorizedAlert = alert }
            .store(in: &subscribers)

        cameraManager.sampleBufferPublisher
            .throttle(for: 0.35, scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            // Drop the first ~2 seconds to allow the user to settle in
            .dropFirst(5)
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)
    }

    func analyzeImage(image: CVPixelBuffer) {}

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
