import ARKit
import Combine
import Foundation

class SelfieViewModel: ObservableObject, ARKitSmileDelegate {
    // Constants
    // TODO: Some of the thresholds may need to be tuned
    private let intraImageMinDelay: TimeInterval = 0.35
    private let noFaceResetDelay: TimeInterval = 3
    private let minFaceAreaThreshold = 0.15
    private let maxFaceAreaThreshold = 0.25
    private let faceRotationThreshold = 0.75
    private let numLivenessImages = 7
    private let numTotalSteps = 8 // numLivenessImages + 1 selfie image
    private let livenessImageSize = 320
    private let selfieImageSize = 640
    
    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let faceDetector = FaceDetector()

    var cameraManager = CameraManager(orientation: .portrait)
    var shouldAnalyzeImages = true
    var currentlyAnalyzingImage = false
    var lastAutoCaptureTime = Date()
    var previousHeadRoll = Double.infinity
    var previousHeadPitch = Double.infinity
    var previousHeadYaw = Double.infinity
    var isSmiling = false
    var selfieImage: URL?
    var livenessImages: [URL] = []
    var jobStatusResponse: SmartSelfieJobStatusResponse?
    var error: Error?
    private var subscriber: AnyCancellable?

    // UI Properties
    @Published var directive: String = "Instructions.Unstable"
    @Published var processingState: ProcessingState?
    @Published var selfieToConfirm: Data?
    @Published var captureProgress: Double = 0
    @Published var useBackCamera = false {
        // This is toggled by a Binding
        didSet { switchCamera() }
    }

    init(
        isEnroll: Bool,
        userId: String,
        jobId: String,
        allowNewEnroll: Bool,
        skipApiSubmission: Bool,
        extraPartnerParams: [String: String]
    ) {
        self.isEnroll = isEnroll
        self.userId = userId
        self.jobId = jobId
        self.allowNewEnroll = allowNewEnroll
        self.skipApiSubmission = skipApiSubmission
        self.extraPartnerParams = extraPartnerParams
        subscriber = self.cameraManager.sampleBufferPublisher
            .receive(on: DispatchQueue.global())
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
    }

    func analyzeImage(image: CVImageBuffer) {
        let elapsedtime = Date().timeIntervalSince(lastAutoCaptureTime)
        print("In here")
        if !shouldAnalyzeImages || currentlyAnalyzingImage || elapsedtime < intraImageMinDelay {
            print("Skipping image analysis")
            return
        }
        currentlyAnalyzingImage = true
        do {
            try faceDetector.detect(imageBuffer: image) { [self] request, error in
                if let error = error {
                    print("Error analyzing image: \(error.localizedDescription)")
                    self.error = error
                    currentlyAnalyzingImage = false
                    return
                }
                guard let results = request.results as? [VNFaceObservation] else {
                    print("Did not receive the expected [VNFaceObservation]")
                    currentlyAnalyzingImage = false
                    return
                }
                if results.count == 0 {
                    print("No faces")
                    DispatchQueue.main.async { self.directive = "Instructions.UnableToDetectFace" }
                    currentlyAnalyzingImage = false
                    return
                }
                
                if results.count > 1 {
                    print("Too many faces")
                    DispatchQueue.main.async { self.directive = "Instructions.MultipleFaces" }
                    currentlyAnalyzingImage = false
                    return
                }
                
                guard let face = results.first else {
                    print("Unexpectedly got an empty face array")
                    currentlyAnalyzingImage = false
                    return
                }
                
        //        let boundingBox = face.boundingBox
                //        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(
                //            rect: result.boundingBox
                //        )

                //        if !faceInFrame(analysisResult.boundingBox) {
        //            DispatchQueue.main.async { self.directive = "Instructions.Start" }
                // self.currentlyAnalyzingImage = false
        //            return
        //        }
                
        //        let faceFillRatio = calculateFaceFill(boundingBox)
        //        if faceFillRatio < minFaceAreaThreshold {
        //            DispatchQueue.main.async { self.directive = "Instructions.FaceFar" }
                // self.currentlyAnalyzingImage = false
        //            return
        //        }
        //
        //        if faceFillRatio > maxFaceAreaThreshold {
        //            DispatchQueue.main.async { self.directive = "Instructions.FaceClose" }
                // self.currentlyAnalyzingImage = false
        //            return
        //        }
                
                // Need to say Smile as the directive regardless because it is possible Smile detection is not possible
                DispatchQueue.main.async { self.directive = "Instructions.Smile" }
                
        //        if !analysisResult.isSmiling && livenessImages.count < numLivenessImages {
                // self.currentlyAnalyzingImage = false
        //            return
        //        }
            
                
                // Perform the rotation checks *after* changing directive to Capturing -- we don't want
                // to explicitly tell the user to move their head
                if !hasFaceRotatedEnough(face: face) {
                    print("Not enough face rotation between captures. Waiting...")
                    currentlyAnalyzingImage = false
                    return
                }
                previousHeadRoll = face.roll?.doubleValue ?? Double.infinity
                previousHeadYaw = face.yaw?.doubleValue ?? Double.infinity
                if #available(iOS 15, *) {
                    self.previousHeadPitch = face.pitch?.doubleValue ?? Double.infinity
                }

                lastAutoCaptureTime = Date()
                do {
                    if livenessImages.count < numLivenessImages {
                        print("Saving liveness image")
                        guard let imageData = ImageUtils.resizePixelBufferToHeight(
                            image,
                            height: livenessImageSize
                        ) else {
                            throw SmileIDError.unknown("Error resizing liveness image")
                        }
                        let imageUrl = try LocalStorage.saveImage(image: imageData, name: "liveness")
                        livenessImages.append(imageUrl)
                        DispatchQueue.main.async {
                            self.captureProgress = Double(self.livenessImages.count) / Double(self.numTotalSteps)
                        }
                    } else {
                        print("Saving selfie image")
                        shouldAnalyzeImages = false
                        guard let imageData = ImageUtils.resizePixelBufferToHeight(
                            image,
                            height: selfieImageSize
                        ) else {
                            throw SmileIDError.unknown("Error resizing selfie image")
                        }
                        let selfieImage = try LocalStorage.saveImage(image: imageData, name: "selfie")
                        self.selfieImage = selfieImage
                        DispatchQueue.main.async {
                            self.captureProgress = 1
                            self.selfieToConfirm = imageData
                        }
                    }
                    currentlyAnalyzingImage = false
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                    self.error = error
                    DispatchQueue.main.async { self.processingState = .error }
                    currentlyAnalyzingImage = false
                    return
                }
                
            }
        } catch {
            print("Error analyzing image: \(error.localizedDescription)")
            currentlyAnalyzingImage = false
            return
        }
    }
    
    func hasFaceRotatedEnough(face: VNFaceObservation) -> Bool {
        guard let roll = face.roll?.doubleValue, let yaw = face.yaw?.doubleValue else {
            print("Roll and yaw unexpectedly nil")
            return true
        }
        var didPitchChange = false
        if #available(iOS 15, *) {
            if let pitch = face.pitch?.doubleValue {
                didPitchChange = abs(pitch - previousHeadPitch) > faceRotationThreshold
            }
        }
        let rollDelta = abs(roll - previousHeadRoll)
        let yawDelta = abs(yaw - previousHeadYaw)
        return didPitchChange || rollDelta > faceRotationThreshold || yawDelta > faceRotationThreshold
    }

    func onSmiling(isSmiling: Bool) {
        self.isSmiling = isSmiling
    }

    func switchCamera() {
        self.cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    }

    func onSelfieRejected() {
        DispatchQueue.main.async {
            self.captureProgress = 0
            self.processingState = nil
            self.selfieToConfirm = nil
        }
        selfieImage = nil
        livenessImages = []
        jobStatusResponse = nil
        shouldAnalyzeImages = true
    }

    func onRetry() {
        // If selfie file is present, all captures were completed, so we're retrying a network issue
        if selfieImage != nil && livenessImages.count == numLivenessImages {
            submitJob()
        } else {
            shouldAnalyzeImages = true
            DispatchQueue.main.async { self.processingState = nil }
        }
    }

    func submitJob() {
        if skipApiSubmission {
            DispatchQueue.main.async { self.processingState = .success }
            return
        }
        DispatchQueue.main.async { self.processingState = .inProgress }
        Task {
            do {
                guard let selfieImage, livenessImages.count == numLivenessImages else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                let infoJson = try LocalStorage.createInfoJson(
                    selfie: selfieImage,
                    livenessImages: livenessImages
                )
                let zipUrl = try LocalStorage.zipFiles(
                    at: livenessImages + [selfieImage] + [infoJson]
                )
                let zip = try Data(contentsOf: zipUrl)
                let jobType = isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: isEnroll,
                    jobId: jobId,
                    userId: userId
                )
                let authResponse = try await SmileID.api.authenticate(request: authRequest).async()
                let prepUploadRequest = PrepUploadRequest(
                    partnerParams: authResponse.partnerParams.copy(extras: extraPartnerParams),
                    allowNewEnroll: String(allowNewEnroll),
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                let prepUploadResponse = try await SmileID.api.prepUpload(
                    request: prepUploadRequest
                ).async()
                let _ = try await SmileID.api.upload(
                    zip: zip,
                    to: prepUploadResponse.uploadUrl
                ).async()
                let jobStatusRequest = JobStatusRequest(
                    userId: userId,
                    jobId: jobId,
                    includeImageLinks: false,
                    includeHistory: false,
                    timestamp: authResponse.timestamp,
                    signature: authResponse.signature
                )
                jobStatusResponse = try await SmileID.api.getJobStatus(
                    request: jobStatusRequest
                ).async()
                DispatchQueue.main.async { self.processingState = .success }
            } catch {
                print("Error submitting job: \(error)")
                self.error = error
                DispatchQueue.main.async { self.processingState = .error }
            }
        }
    }

    func onFinished(callback: SmartSelfieResultDelegate) {
        if let selfieImage, livenessImages.count == numLivenessImages {
            callback.didSucceed(
                selfieImage: selfieImage,
                livenessImages: livenessImages,
                jobStatusResponse: jobStatusResponse
            )
        } else if let error {
            callback.didError(error: error)
        } else {
            callback.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }
}
