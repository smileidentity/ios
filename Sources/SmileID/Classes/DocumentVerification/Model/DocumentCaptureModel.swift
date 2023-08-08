import Foundation
import Combine
import CoreVideo

class DocumentCaptureViewModel: ObservableObject, JobSubmittable {
    private var userId: String
    private var jobId: String
    private var document: Document
    private var currentBuffer: CVPixelBuffer?
    private var subscribers = Set<AnyCancellable>()
    private var cameraFeedSubscriber: AnyCancellable?
    private (set) lazy var cameraManager: CameraManageable = CameraManager()

    var navTitle: String {
        return "Nigeria National ID Card"
    }

    init(userId: String, jobId: String, document: Document) {
        self.userId = userId
        self.jobId = jobId
        self.document = document
    }

    func subscribeToCameraFeed() {
       cameraFeedSubscriber = cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue.global())
            .compactMap({$0})
            .sink( receiveValue: { buffer in
                
            })
    }

    func captureImage() {

    }

    func resetState() {

    }

    func pauseCameraSession() {

    }

    func getDocumentAspectRatio() {
        
    }

    func submitJob(zip: Data) {
        let authRequest = AuthenticationRequest(jobType: .documentVerification,
                                                enrollment: false,
                                                jobId: jobId,
                                                userId: userId)

        SmileID.api.authenticate(request: authRequest)
            .flatMap { authResponse in
                self.prepUpload(authResponse)
                    .flatMap { prepUploadResponse in
                        self.upload(prepUploadResponse, zip: zip)
                            .filter { result in
                                switch result {
                                case .response:
                                    return true
                                default:
                                    return false
                                }
                            }
                            .map { _ in authResponse }
                    }
            }
            .flatMap(pollJobStatus)
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        if let error = error as? SmileIDError {

                        }
                    }
                default:
                    break
                }
            }, receiveValue: { [weak self] response in
                DispatchQueue.main.async {

                }
            }).store(in: &subscribers)
    }
}
