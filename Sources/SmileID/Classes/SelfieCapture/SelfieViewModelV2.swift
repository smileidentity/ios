import ARKit
import Combine
import Foundation

// swiftlint:disable opening_brace
public class SelfieViewModelV2: ObservableObject, ARKitSmileDelegate {
    // Constants
    private let intraImageMinDelay: TimeInterval = 0.35
    private let noFaceResetDelay: TimeInterval = 3
    private let faceCaptureQualityThreshold: Float = 0.25
    private let minFaceCenteredThreshold = 0.1
    private let maxFaceCenteredThreshold = 0.9
    private let minFaceAreaThreshold = 0.125
    private let maxFaceAreaThreshold = 0.25
    private let faceRotationThreshold = 0.035
    private let numLivenessImages = 7
    private let numTotalSteps = 8 // numLivenessImages + 1 selfie image
    private let livenessImageSize = 320
    private let selfieImageSize = 640
    private let faceQualityThreshold: Float = 0.5
    private let selfieQualityHistoryLength: Int = 5

    private let isEnroll: Bool
    private let userId: String
    private let jobId: String
    private let allowNewEnroll: Bool
    private let skipApiSubmission: Bool
    private let extraPartnerParams: [String: String]
    private let useStrictMode: Bool
    private let faceDetector = FaceDetector()

    var cameraManager = CameraManager(orientation: .portrait)
    var shouldAnalyzeImages = true
    var lastAutoCaptureTime = Date()
    var previousHeadRoll = Double.infinity
    var previousHeadPitch = Double.infinity
    var previousHeadYaw = Double.infinity
    var isSmiling = false
    var currentlyUsingArKit: Bool { ARFaceTrackingConfiguration.isSupported && !useBackCamera }

    var selfieImage: URL?
    var livenessImages: [URL] = []
    private var selfieQualityHistory: [Float] = []
    var apiResponse: SmartSelfieResponse?
    var error: Error?

    private let arKitFramePublisher = PassthroughSubject<CVPixelBuffer?, Never>()
    private var subscribers = Set<AnyCancellable>()

    // UI Properties
    @Published var unauthorizedAlert: AlertState?
    @Published var directive: String = "Instructions.Start"
    /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
    /// and use `errorMessage` to show the actual platform error message that we show if
    /// `errorMessageRes` is not set by the partner
    @Published var errorMessageRes: String?
    @Published var errorMessage: String?
    @Published var processingState: ProcessingState?
    @Published var selfieToConfirm: Data?
    @Published var captureProgress: Double = 0
    @Published var useBackCamera = false {
        // This is toggled by a Binding
        didSet { switchCamera() }
    }

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
            .merge(with: arKitFramePublisher)
            .throttle(for: 0.35, scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            // Drop the first ~2 seconds to allow the user to settle in
            .dropFirst(5)
            .compactMap { $0 }
            .sink(receiveValue: analyzeImage)
            .store(in: &subscribers)
    }
    
    private func checkSelfieQuality(pixelBuffer: CVPixelBuffer) {
        guard let image = UIImage(pixelBuffer: pixelBuffer), 
                let mlMultiArray = image.toMLMultiArray() else {
            print("Failed to preprocess image")
            return
        }

        do {
            // Load the model
            let model = try ImageQualityCP20(configuration: MLModelConfiguration())

            // Create the input feature provider
            let input = ImageQualityCP20Input(conv2d_193_input: mlMultiArray)

            // Perform the prediction
            let prediction = try model.prediction(input: input)
            
            // Handle the output multi-array
            // Extract the output MLMultiArray
            if let output = prediction.featureValue(for: "Identity")?.multiArrayValue {
                print("Output MultiArray: \(output)")
                processOutput(output)
            }

        } catch {
            print("Error initializing model: \(error.localizedDescription)")
        }
    }
    
    func processOutput(_ output: MLMultiArray) {
        let shape = output.shape.map { $0.intValue }
        let count = shape.reduce(1, *)
        print("count -", count)

        var values = [Float32]()
        let dataPointer = UnsafePointer<Float32>(OpaquePointer(output.dataPointer))
        for index in 0..<count {
            values.append(dataPointer[index])
        }

        // update quality history
        selfieQualityHistory.append(values.first ?? 0)
        if selfieQualityHistory.count > selfieQualityHistoryLength {
            selfieQualityHistory.removeFirst()
        }

        // quality check
        let averageFaceQuality = selfieQualityHistory.reduce(0, +) / Float(selfieQualityHistory.count)
        if averageFaceQuality < faceQualityThreshold {
            print("Face quality not Met")
            return
        }

        print("Processed output values: \(values)")
    }
    
    // swiftlint:disable cyclomatic_complexity
    func analyzeImage(image: CVPixelBuffer) {
        let elapsedtime = Date().timeIntervalSince(lastAutoCaptureTime)
        if !shouldAnalyzeImages || elapsedtime < intraImageMinDelay {
            return
        }

        do {
            try faceDetector.detect(imageBuffer: image) { [self] request, error in
                if let error {
                    print("Error analyzing image: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let results = request.results as? [VNFaceObservation] else {
                    print("Did not receive the expected [VNFaceObservation]")
                    return
                }

                if results.count == 0 {
                    DispatchQueue.main.async { self.directive = "Instructions.UnableToDetectFace" }
                    // If no faces are detected for a while, reset the state
                    if elapsedtime > noFaceResetDelay {
                        DispatchQueue.main.async {
                            self.captureProgress = 0
                            self.selfieToConfirm = nil
                            self.processingState = nil
                        }
                        selfieImage = nil
                        livenessImages = []
                    }
                    return
                }

                // Ensure only 1 face is in frame
                if results.count > 1 {
                    DispatchQueue.main.async { self.directive = "Instructions.MultipleFaces" }
                    return
                }

                guard let face = results.first else {
                    print("Unexpectedly got an empty face array")
                    return
                }

                // The coordinate system of the bounding box in VNFaceObservation is such that
                // the camera view spans [0-1]x[0-1] and the face is within that. Since we don't
                // need to draw on the camera view, we don't need to convert this to the view's
                // coordinate system. We can calculate out of bounds and face area directly on this
                let boundingBox = face.boundingBox

                // Check that the corners of the face bounding box are within frame
                if boundingBox.minX < minFaceCenteredThreshold
                    || boundingBox.minY < minFaceCenteredThreshold
                    || boundingBox.maxX > maxFaceCenteredThreshold
                    || boundingBox.maxY > maxFaceCenteredThreshold
                {
                    DispatchQueue.main.async { self.directive = "Instructions.PutFaceInOval" }
                    return
                }

                // image's area is equal to 1. so (bbox area / image area) == bbox area
                let faceFillRatio = boundingBox.width * boundingBox.height
                if faceFillRatio < minFaceAreaThreshold {
                    DispatchQueue.main.async { self.directive = "Instructions.MoveCloser" }
                    return
                }

                if faceFillRatio > maxFaceAreaThreshold {
                    DispatchQueue.main.async { self.directive = "Instructions.MoveFarther" }
                    return
                }

                if let quality = face.faceCaptureQuality, quality < faceCaptureQualityThreshold {
                    DispatchQueue.main.async { self.directive = "Instructions.Quality" }
                    return
                }

                let userNeedsToSmile = livenessImages.count > numLivenessImages / 2

                DispatchQueue.main.async { [self] in
                    directive = userNeedsToSmile ? "Instructions.Smile" : "Instructions.Capturing"
                }

                // TODO: Use mouth deformation as an alternate signal for non-ARKit capture
                if userNeedsToSmile, currentlyUsingArKit, !isSmiling {
                    return
                }

                // Perform the rotation checks *after* changing directive to Capturing -- we don't
                // want to explicitly tell the user to move their head
                if !hasFaceRotatedEnough(face: face) {
                    print("Not enough face rotation between captures. Waiting...")
                    return
                }

                // Feels like a perfect place to run Selfie Quality Check
                // Right now doesn't break the current flow of image analysis.
                checkSelfieQuality(pixelBuffer: image)

                let orientation = currentlyUsingArKit ? CGImagePropertyOrientation.right : .up
                lastAutoCaptureTime = Date()
                do {
                    if livenessImages.count < numLivenessImages {
                        guard let imageData = ImageUtils.resizePixelBufferToHeight(
                            image,
                            height: livenessImageSize,
                            orientation: orientation
                        ) else {
                            throw SmileIDError.unknown("Error resizing liveness image")
                        }
                        let imageUrl = try LocalStorage.createLivenessFile(jobId: jobId, livenessFile: imageData)
                        livenessImages.append(imageUrl)
                        DispatchQueue.main.async {
                            self.captureProgress = Double(self.livenessImages.count) / Double(self.numTotalSteps)
                        }
                    } else {
                        shouldAnalyzeImages = false
                        guard let imageData = ImageUtils.resizePixelBufferToHeight(
                            image,
                            height: selfieImageSize,
                            orientation: orientation
                        ) else {
                            throw SmileIDError.unknown("Error resizing selfie image")
                        }
                        let selfieImage = try LocalStorage.createSelfieFile(jobId: jobId, selfieFile: imageData)
                        self.selfieImage = selfieImage
                        DispatchQueue.main.async {
                            self.captureProgress = 1
                            self.selfieToConfirm = imageData
                        }
                    }
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                    self.error = error
                    DispatchQueue.main.async { self.processingState = .error }
                    return
                }
            }
        } catch {
            print("Error analyzing image: \(error.localizedDescription)")
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

        previousHeadRoll = face.roll?.doubleValue ?? Double.infinity
        previousHeadYaw = face.yaw?.doubleValue ?? Double.infinity
        if #available(iOS 15, *) {
            self.previousHeadPitch = face.pitch?.doubleValue ?? Double.infinity
        }

        return didPitchChange || rollDelta > faceRotationThreshold || yawDelta > faceRotationThreshold
    }

    func onSmiling(isSmiling: Bool) {
        self.isSmiling = isSmiling
    }

    func onARKitFrame(frame: ARFrame) {
        arKitFramePublisher.send(frame.capturedImage)
    }

    func switchCamera() {
        cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    }

    func onSelfieRejected() {
        DispatchQueue.main.async {
            self.captureProgress = 0
            self.processingState = nil
            self.selfieToConfirm = nil
        }
        selfieImage = nil
        livenessImages = []
        shouldAnalyzeImages = true
    }

    func onRetry() {
        // If selfie file is present, all captures were completed, so we're retrying a network issue
        if selfieImage != nil, livenessImages.count == numLivenessImages {
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
                let jobType = isEnroll ? JobType.smartSelfieEnrollment : JobType.smartSelfieAuthentication
                let authRequest = AuthenticationRequest(
                    jobType: jobType,
                    enrollment: isEnroll,
                    jobId: jobId,
                    userId: userId
                )
                if SmileID.allowOfflineMode {
                    try LocalStorage.saveOfflineJob(
                        jobId: jobId,
                        userId: userId,
                        jobType: jobType,
                        enrollment: isEnroll,
                        allowNewEnroll: allowNewEnroll,
                        partnerParams: extraPartnerParams
                    )
                }
                let authResponse = try await SmileID.api.authenticate(request: authRequest)

                var smartSelfieLivenessImages = [MultipartBody]()
                var smartSelfieImage: MultipartBody?
                if let selfie = try? Data(contentsOf: selfieImage), let media = MultipartBody(
                    withImage: selfie,
                    forKey: selfieImage.lastPathComponent,
                    forName: selfieImage.lastPathComponent
                ) {
                    smartSelfieImage = media
                }
                if !livenessImages.isEmpty {
                    let livenessImageInfos = livenessImages.compactMap { liveness -> MultipartBody? in
                        if let data = try? Data(contentsOf: liveness) {
                            return MultipartBody(
                                withImage: data,
                                forKey: liveness.lastPathComponent,
                                forName: liveness.lastPathComponent
                            )
                        }
                        return nil
                    }

                    smartSelfieLivenessImages.append(contentsOf: livenessImageInfos.compactMap { $0 })
                }
                guard let smartSelfieImage = smartSelfieImage,
                smartSelfieLivenessImages.count == numLivenessImages else {
                    throw SmileIDError.unknown("Selfie capture failed")
                }
                let response = if isEnroll {
                    try await SmileID.api.doSmartSelfieEnrollment(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        userId: userId,
                        partnerParams: extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil,
                        allowNewEnroll: allowNewEnroll
                    )
                } else {
                    try await SmileID.api.doSmartSelfieAuthentication(
                        signature: authResponse.signature,
                        timestamp: authResponse.timestamp,
                        userId: userId,
                        selfieImage: smartSelfieImage,
                        livenessImages: smartSelfieLivenessImages,
                        partnerParams: extraPartnerParams,
                        callbackUrl: SmileID.callbackUrl,
                        sandboxResult: nil
                    )
                }
                apiResponse = response
                do {
                    try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
                    self.selfieImage = try LocalStorage.getFileByType(
                        jobId: jobId,
                        fileType: FileType.selfie,
                        submitted: true
                    )
                    self.livenessImages = try LocalStorage.getFilesByType(
                        jobId: jobId,
                        fileType: FileType.liveness,
                        submitted: true
                    ) ?? []
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                }
                DispatchQueue.main.async { self.processingState = .success }
            } catch let error as SmileIDError {
                do {
                    let didMove = try LocalStorage.handleOfflineJobFailure(
                        jobId: self.jobId,
                        error: error
                    )
                    if didMove {
                        self.selfieImage = try LocalStorage.getFileByType(
                            jobId: jobId,
                            fileType: FileType.selfie,
                            submitted: true
                        )
                        self.livenessImages = try LocalStorage.getFilesByType(
                            jobId: jobId,
                            fileType: FileType.liveness,
                            submitted: true
                        ) ?? []
                    }
                } catch {
                    print("Error moving job to submitted directory: \(error)")
                    self.error = error
                    return
                }
                if SmileID.allowOfflineMode, LocalStorage.isNetworkFailure(error: error) {
                    DispatchQueue.main.async {
                        self.errorMessageRes = "Offline.Message"
                        self.processingState = .success
                    }
                } else {
                    print("Error submitting job: \(error)")
                    let (errorMessageRes, errorMessage) = toErrorMessage(error: error)
                    self.error = error
                    self.errorMessageRes = errorMessageRes
                    self.errorMessage = errorMessage
                    DispatchQueue.main.async { self.processingState = .error }
                }
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
                apiResponse: apiResponse
            )
        } else if let error {
            callback.didError(error: error)
        } else {
            callback.didError(error: SmileIDError.unknown("Unknown error"))
        }
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
