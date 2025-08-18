import ARKit
import Combine
import Foundation

public class SelfieViewModel: ObservableObject, ARKitSmileDelegate {
  // MARK: - Constants

  private enum Constants {
    static let intraImageMinDelay: TimeInterval = 0.35
    static let noFaceResetDelay: TimeInterval = 3
    static let faceCaptureQualityThreshold: Float = 0.25
    static let minFaceCenteredThreshold = 0.1
    static let maxFaceCenteredThreshold = 0.9
    static let minFaceAreaThreshold = 0.125
    static let maxFaceAreaThreshold = 0.25
    static let faceRotationThreshold = 0.03
    static let faceRollThreshold = 0.025 // roll has a smaller range than yaw
    static let numLivenessImages = 7
    static var numTotalSteps: Int { numLivenessImages + 1 } // numLivenessImages + 1 selfie image
    static let livenessImageSize = 320
    static let selfieImageSize = 640
  }

  /// Keys used by UI to look up localized instruction strings.
  private enum Directive: String {
    case start = "Instructions.Start"
    case unableToDetectFace = "Instructions.UnableToDetectFace"
    case multipleFaces = "Instructions.MultipleFaces"
    case putFaceInOval = "Instructions.PutFaceInOval"
    case moveCloser = "Instructions.MoveCloser"
    case moveFarther = "Instructions.MoveFarther"
    case quality = "Instructions.Quality"
    case smile = "Instructions.Smile"
    case capturing = "Instructions.Capturing"
  }

  // MARK: - Immutable Configuration

  private let isEnroll: Bool
  private let userId: String
  private let jobId: String
  private let allowNewEnroll: Bool
  private let skipApiSubmission: Bool
  private let extraPartnerParams: [String: String]

  // MARK: Dependencies

  private let metadata: Metadata = .shared
  private let faceDetector = FaceDetector()
  private let faceTrackingManager = FaceTrackingManager()

  // MARK: - Timing / State

  private var captureDuration = MonotonicTime()
  private var networkRetries: Int = 0
  private var selfieCaptureRetries: Int = 0
  private var hasRecordedOrientationAtCaptureStart = false
  var lastAutoCaptureTime = Date()

  // Prior head pose readings (roll/pitch/yaw) used to gate auto-capture variety.
  private var previousHeadRoll = Double.infinity
  private var previousHeadPitch = Double.infinity
  private var previousHeadYaw = Double.infinity

  // ARKit Smile Signal
  private var isSmiling = false

  // MARK: - Camera

  var cameraManager = CameraManager(orientation: .portrait)
  var shouldAnalyzeImages = true
  var currentlyUsingArKit: Bool {
    ARFaceTrackingConfiguration.isSupported && !useBackCamera
  }

  // MARK: - Capture Artifacts

  var selfieImage: URL?
  var livenessImages: [URL] = []
  var apiResponse: SmartSelfieResponse?
  var error: Error?

  // MARK: - Combine

  private let arKitFramePublisher = PassthroughSubject<
    CVPixelBuffer?, Never
  >()
  private var subscribers = Set<AnyCancellable>()

  // MARK: - UI Published Properties

  @Published var unauthorizedAlert: AlertState?
  @Published var directive: String = Directive.start.rawValue
  /// we use `errorMessageRes` to map to the actual code to the stringRes to allow localization,
  /// and use `errorMessage` to show the actual platform error message that we show if
  /// `errorMessageRes` is not set by the partner
  @Published public var errorMessageRes: String?
  @Published public var errorMessage: String?
  @Published public private(set) var processingState: ProcessingState?
  @Published public private(set) var selfieToConfirm: Data?
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
    extraPartnerParams: [String: String]
  ) {
    self.isEnroll = isEnroll
    self.userId = userId
    self.jobId = jobId
    self.allowNewEnroll = allowNewEnroll
    self.skipApiSubmission = skipApiSubmission
    self.extraPartnerParams = extraPartnerParams

    faceTrackingManager.delegate = self

    configureCameraSession()
    bindCameraAuthorization()
    bindFrameStream()

    // Initial metadata for camera facing.
    let cameraFacing: CameraFacingValue =
      useBackCamera
        ? .backCamera : .frontCamera
    metadata.addMetadata(
      key: .selfieImageOrigin,
      value: cameraFacing.rawValue
    )
  }

  deinit {
    // Clean up face tracking
    faceTrackingManager.resetTracking()
    faceTrackingManager.delegate = nil

    // Cancel all Combine subscriptions
    subscribers.removeAll()
  }

  // MARK: - Setup Helpers

  private func configureCameraSession() {
    if cameraManager.session.canSetSessionPreset(.vga640x480) {
      cameraManager.session.sessionPreset = .vga640x480
    }
  }

  /// Observe camera authorization state and surface alert.
  private func bindCameraAuthorization() {
    cameraManager.$status
      .receive(on: DispatchQueue.main)
      .filter { $0 == .unauthorized }
      .map { _ in AlertState.cameraUnauthorized }
      .sink { [weak self] alert in self?.unauthorizedAlert = alert }
      .store(in: &subscribers)
  }

  /// Merge camera & ARKit frame pipelines, throttle,
  /// discard initial settling frames and forward to image analysis
  private func bindFrameStream() {
    cameraManager.sampleBufferPublisher
      .receive(on: DispatchQueue.main)
      .merge(with: arKitFramePublisher)
      .throttle(
        for: 0.35,
        scheduler: DispatchQueue.global(qos: .userInitiated),
        latest: true
      )
      // Drop the first ~2 seconds to allow the user to settle in
      .dropFirst(5)
      .compactMap { $0 }
      .sink { [weak self] imageBuffer in
        self?.analyzeImage(image: imageBuffer)
      }
      .store(in: &subscribers)
  }

  // MARK: - Frame Analysis Pipeline

  /// Entry point for per-frame analysis.
  /// Performs a cascade of validations and, when all pass,
  /// auto-captures either a liveness frame or the final selfie frame.
  func analyzeImage(image: CVPixelBuffer) {
    recordCaptureStartIfNeeded()

    // Forward every frame to the tracker
    faceTrackingManager.processFrame(image, orientation: .leftMirrored)

    // Enforce minimal spacing between auto captures
    let elapsed = Date().timeIntervalSince(lastAutoCaptureTime)
    guard shouldAnalyzeImages, elapsed >= Constants.intraImageMinDelay else { return }

    do {
      try faceDetector.detect(imageBuffer: image) { [weak self] request, error in
        guard let self else { return }
        if let error {
          debug("Face detection error: \(error.localizedDescription)", category: "SelfieViewModel")
          self.error = error
          return
        }

        guard let faces = request.results as? [VNFaceObservation] else {
          debug("Unexpected detection result type.", category: "SelfieViewModel")
          return
        }

        self.handleDetectionResults(
          faces,
          elapsed: elapsed,
          image: image
        )
      }
    } catch {
      debug("Vision request error: \(error.localizedDescription)", category: "SelfieViewModel")
    }
  }

  /// Handles Vision results (on Vision callback thread).
  private func handleDetectionResults(
    _ faces: [VNFaceObservation],
    elapsed: TimeInterval,
    image: CVPixelBuffer
  ) {
    // No faces
    if faces.isEmpty {
      updateDirective(.unableToDetectFace)
      // Reset if user leaves frame for too long.
      if elapsed > Constants.noFaceResetDelay {
        debug("Resetting capture due to prolonged no-face condition.", category: "SelfieViewModel")
        resetCaptureUIState()
        selfieImage = nil
        livenessImages = []
        cleanUpSelfieCapture()
      }

      // Clear tracking when no face present
      faceTrackingManager.resetTracking()

      return
    }

    // Multiple faces not allowed
    if faces.count > 1 {
      updateDirective(.multipleFaces)
      return
    }

    guard let face = faces.first else {
      debug("faces.first unexpectedly nil after non-empty check.", category: "SelfieViewModel")
      return
    }

    // Start face tracking on the first detected face
    if !faceTrackingManager.isTracking {
      faceTrackingManager.startTracking(with: face)
    }

    guard validateFacePosition(face) else { return }
    guard validateFaceArea(face) else { return }
    guard validateFaceQuality(face) else { return }

    let userNeedsToSmile = livenessImages.count > Constants.numLivenessImages / 2
    updateDirective(userNeedsToSmile ? .smile : .capturing)

    // TODO: Use mouth deformation as an alternative signal for non-ARKit capture
    if userNeedsToSmile, currentlyUsingArKit, !isSmiling {
      debug("Awaiting smile signal from ARKit.", category: "SelfieViewModel")
      return
    }

    // Perform the rotation checks *after* changing directive to Capturing
    // -- we don't want to explicitly tell the user to move their head.
    guard hasFaceRotatedEnough(face: face) else {
      debug(
        "Insufficient head rotation; waiting for movement to ensure diversity.",
        category: "SelfieViewModel")
      return
    }

    // All good - perform capture.
    let orientation: CGImagePropertyOrientation = getUprightOrientation()
    lastAutoCaptureTime = Date()
    do {
      try captureFrame(image, orientation: orientation)
    } catch {
      debug("Error saving image: \(error.localizedDescription)", category: "SelfieViewModel")
      self.error = error
      updateOnMain { self.processingState = .error }
    }
  }

  // MARK: - Validation Helpers

  /// Ensure bounding box stays within the safe central region
  private func validateFacePosition(_ face: VNFaceObservation) -> Bool {
    let boundingBox = face.boundingBox
    if boundingBox.minX < Constants.minFaceCenteredThreshold
      || boundingBox.minY < Constants.minFaceCenteredThreshold
      || boundingBox.maxX > Constants.maxFaceCenteredThreshold
      || boundingBox.maxY > Constants.maxFaceCenteredThreshold {
      updateDirective(.putFaceInOval)
      return false
    }
    return true
  }

  /// Ensures the face fills an acceptable area range.
  private func validateFaceArea(_ face: VNFaceObservation) -> Bool {
    let bbox = face.boundingBox
    let faceFillRatio = bbox.width * bbox.height // image area normalized to 1.0
    if faceFillRatio < Constants.minFaceAreaThreshold {
      updateDirective(.moveCloser)
      return false
    }
    if faceFillRatio > Constants.maxFaceAreaThreshold {
      updateDirective(.moveFarther)
      return false
    }
    return true
  }

  /// Ensures Vision-estimated face quality meets threshold (when available).
  private func validateFaceQuality(_ face: VNFaceObservation) -> Bool {
    if let quality = face.faceCaptureQuality, quality < Constants.faceCaptureQualityThreshold {
      updateDirective(.quality)
      return false
    }
    return true
  }

  // MARK: - Capture Helpers

  /// Captures either a liveness frame or the final selfie frame, resizing and persisting to disk.
  private func captureFrame(
    _ image: CVPixelBuffer,
    orientation: CGImagePropertyOrientation
  ) throws {
    if livenessImages.count < Constants.numLivenessImages {
      guard
        let imageData = ImageUtils.resizePixelBufferToHeight(
          image,
          height: Constants.livenessImageSize,
          orientation: orientation
        )
      else {
        throw SmileIDError.unknown("Error resizing liveness image")
      }

      let imageURL = try LocalStorage.createLivenessFile(
        jobId: jobId,
        livenessFile: imageData
      )
      livenessImages.append(imageURL)
      updateCaptureProgress()
    } else {
      shouldAnalyzeImages = false
      guard
        let imageData = ImageUtils.resizePixelBufferToHeight(
          image,
          height: Constants.selfieImageSize,
          orientation: orientation
        )
      else {
        throw SmileIDError.unknown("Error resizing selfie image")
      }
      let selfieURL = try LocalStorage.createSelfieFile(
        jobId: jobId,
        selfieFile: imageData
      )
      selfieImage = selfieURL

      recordCaptureEnd()
      updateOnMain {
        self.captureProgress = 1
        self.selfieToConfirm = imageData
      }
    }
  }

  /// Update capture progress (0.0 - 1.0) after liveness capture.
  private func updateCaptureProgress() {
    updateOnMain {
      self.captureProgress =
        Double(self.livenessImages.count)
          / Double(Constants.numTotalSteps)
    }
  }

  // MARK: - Metadata Recording

  /// Records orientation + start time once at beginning of capture session.
  private func recordCaptureStartIfNeeded() {
    guard !hasRecordedOrientationAtCaptureStart else { return }
    metadata.addMetadata(key: .deviceOrientation)
    hasRecordedOrientationAtCaptureStart = true
    captureDuration.startTime()
  }

  /// Records orientation + duration when selfie is captured.
  private func recordCaptureEnd() {
    metadata.addMetadata(key: .deviceOrientation)
    metadata.addMetadata(
      key: .selfieCaptureDuration,
      value: captureDuration.elapsedTime().milliseconds()
    )
  }

  // MARK: - Directive Utilities

  private func updateDirective(_ directive: Directive) {
    updateOnMain { self.directive = directive.rawValue }
  }

  // MARK: - ARKitSmileDelegate

  func onSmiling(isSmiling: Bool) {
    self.isSmiling = isSmiling
  }

  func onARKitFrame(frame: ARFrame) {
    arKitFramePublisher.send(frame.capturedImage)
  }

  // MARK: - Camera Switching

  func switchCamera() {
    cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    metadata.removeMetadata(key: .selfieImageOrigin)
    let cameraFacing: CameraFacingValue = useBackCamera ? .backCamera : .frontCamera
    metadata.addMetadata(key: .selfieImageOrigin, value: cameraFacing.rawValue)
  }

  // MARK: - Public UI Actions

  /// Called when the user rejects the captured selfie and wants to try again.
  public func onSelfieRejected() {
    faceTrackingManager.resetTracking()
    resetCaptureUIState()
    selfieImage = nil
    livenessImages = []
    shouldAnalyzeImages = true
    cleanUpSelfieCapture()
    selfieCaptureRetries += 1

    // Clean metadata keys relevant to the completed capture attempt.
    metadata.removeMetadata(key: .selfieImageOrigin)
    metadata.removeMetadata(key: .activeLivenessType)
    metadata.removeMetadata(key: .selfieCaptureDuration)
    metadata.removeMetadata(key: .deviceOrientation)
    metadata.removeMetadata(key: .deviceMovementDetected)
    hasRecordedOrientationAtCaptureStart = false
  }

  func cleanUpSelfieCapture() {
    do {
      try LocalStorage.deleteLivenessAndSelfieFiles(at: [jobId])
    } catch {
      debugPrint(error.localizedDescription)
    }
  }

  func onRetry() {
    // If selfie file is present, all captures were completed, so we're retrying a network issue
    if selfieImage != nil, livenessImages.count == Constants.numLivenessImages {
      incrementNetworkRetries()
      submitJob()
    } else {
      selfieCaptureRetries += 1
      shouldAnalyzeImages = true
      DispatchQueue.main.async { self.processingState = nil }
    }
  }

  // MARK: - Completion Callback

  public func onFinished(callback: SmartSelfieResultDelegate) {
    if let error {
      callback.didError(error: error)
    } else if let selfieImage, livenessImages.count == Constants.numLivenessImages {
      callback.didSucceed(
        selfieImage: selfieImage,
        livenessImages: livenessImages,
        apiResponse: apiResponse
      )
    } else {
      callback.didError(error: SmileIDError.unknown("Unknown error"))
    }
  }

  // MARK: - Settings

  func openSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString)
    else { return }
    UIApplication.shared.open(settingsURL)
  }

  // MARK: - Head Rotation Gate

  /// Returns `true` if the user has rotated their head sufficiently since the last capture,
  /// helping us collect a diverse set of liveness images.
  func hasFaceRotatedEnough(face: VNFaceObservation) -> Bool {
    guard let roll = face.roll?.doubleValue, let yaw = face.yaw?.doubleValue
    else {
      debug("Roll and yaw unexpectedly nil", category: "SelfieViewModel")
      return true
    }
    var didPitchChange = false
    if #available(iOS 15, *) {
      if let pitch = face.pitch?.doubleValue {
        didPitchChange =
          abs(pitch - previousHeadPitch) > Constants.faceRotationThreshold
      }
    }
    let rollDelta = abs(roll - previousHeadRoll)
    let yawDelta = abs(yaw - previousHeadYaw)

    previousHeadRoll = face.roll?.doubleValue ?? Double.infinity
    previousHeadYaw = face.yaw?.doubleValue ?? Double.infinity
    if #available(iOS 15, *) {
      previousHeadPitch = face.pitch?.doubleValue ?? Double.infinity
    }

    return didPitchChange
      || rollDelta > Constants.faceRollThreshold
      || yawDelta > Constants.faceRotationThreshold
  }

  // MARK: - UI / State Reset

  /// Resets *only* the UI published properties related to an in-progress capture.
  private func resetCaptureUIState() {
    updateOnMain {
      self.captureProgress = 0
      self.selfieToConfirm = nil
      self.processingState = nil
    }
  }

  private func resetForNewFace() {
    resetCaptureUIState()
    selfieImage = nil
    livenessImages = []
    shouldAnalyzeImages = true
    faceTrackingManager.resetTracking()
    cleanUpSelfieCapture()
  }

  // MARK: - Orientation Helper

  /// Returns the correct orientation to ensure upright images regardless of device orientation
  private func getUprightOrientation() -> CGImagePropertyOrientation {
    let deviceOrientation = UIDevice.current.orientation

    if currentlyUsingArKit {
      // ARKit frames need different correction based on device orientation
      switch deviceOrientation {
      case .portrait:
        return .right
      case .portraitUpsideDown:
        return .left
      case .landscapeLeft:
        return .up
      case .landscapeRight:
        return .down
      default:
        return .right // Default for portrait when orientation is unknown
      }
    } else {
      // Regular camera frames need different correction based on device orientation
      switch deviceOrientation {
      case .portrait:
        return .up
      case .portraitUpsideDown:
        return .down
      case .landscapeLeft:
        return .right
      case .landscapeRight:
        return .left
      default:
        return .up // Default for portrait when orientation is unknown
      }
    }
  }

  // MARK: - Main Thread Helper

  /// Ensures UI mutations execute on the main thread.
  @inline(__always) private func updateOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }
}

// MARK: FaceTrackingDelegate

extension SelfieViewModel: FaceTrackingDelegate {
  func faceTrackingStateChanged(_ state: FaceTrackingState) {
    switch state {
    case .detecting:
      updateDirective(.unableToDetectFace)
    case .tracking:
      // A face is locked-on; directive logic will be handled by vision validations
      break
    case .lost:
      updateDirective(.unableToDetectFace)
    case .reset:
      resetForNewFace()
    }
  }

  func faceTrackingDidFail(with error: FaceTrackingError) {
    debug("Face tracking error: \(error)", category: "SelfieViewModel")
    switch error {
    case .multipleFacesDetected:
      updateDirective(.multipleFaces)
    case .noFaceDetected:
      updateDirective(.unableToDetectFace)
    case .trackingLost, .trackingConfidenceTooLow:
      updateDirective(.unableToDetectFace)
    case .differentFaceDetected:
      // Start over when a new face shows up.
      resetForNewFace()
    }
  }

  func faceTrackingDidReset() {
    debug(
      "Face tracking reset - restarting capture flow",
      category: "SelfieViewModel"
    )
    resetForNewFace()
  }
}

// MARK: - Metadata Helpers

extension SelfieViewModel {
  private func incrementNetworkRetries() {
    networkRetries += 1
    Metadata.shared.addMetadata(key: .networkRetries, value: networkRetries)
  }

  private func resetNetworkRetries() {
    networkRetries = 0
    Metadata.shared.removeMetadata(key: .networkRetries)
  }
}

// MARK: - Job Submission

extension SelfieViewModel {
  public func submitJob() {
    metadata.addMetadata(key: .activeLivenessType, value: LivenessType.smile.rawValue)
    metadata.addMetadata(key: .selfieCaptureRetries, value: selfieCaptureRetries)

    // Offline / skip mode short-circuit
    if skipApiSubmission {
      updateOnMain { self.processingState = .success }
      return
    }

    updateOnMain { self.processingState = .inProgress }

    Task {
      do {
        guard let selfieImage, livenessImages.count == Constants.numLivenessImages
        else {
          throw SmileIDError.unknown("Selfie capture failed")
        }
        let jobType: JobType =
          isEnroll
            ? .smartSelfieEnrollment
            : .smartSelfieAuthentication
        let authRequest = AuthenticationRequest(
          jobType: jobType,
          enrollment: isEnroll,
          jobId: jobId,
          userId: userId
        )
        let metadata = metadata.collectAllMetadata()

        if SmileID.allowOfflineMode {
          try LocalStorage.saveOfflineJob(
            jobId: jobId,
            userId: userId,
            jobType: jobType,
            enrollment: isEnroll,
            allowNewEnroll: allowNewEnroll,
            metadata: metadata,
            partnerParams: extraPartnerParams
          )
        }

        try await getExceptionHandler {
          let authResponse = try await SmileID.api.authenticate(
            request: authRequest
          )

          // Build multipart bodies
          var smartSelfieLivenessImages = [MultipartBody]()
          var smartSelfieImage: MultipartBody?

          if let selfie = try? Data(contentsOf: selfieImage),
             let media = MultipartBody(
               withImage: selfie,
               forName: selfieImage.lastPathComponent
             ) {
            smartSelfieImage = media
          }

          if !livenessImages.isEmpty {
            let livenessImageInfos = livenessImages.compactMap { url -> MultipartBody? in
              if let data = try? Data(contentsOf: url) {
                return MultipartBody(
                  withImage: data,
                  forName: url.lastPathComponent
                )
              }
              return nil
            }

            smartSelfieLivenessImages.append(
              contentsOf: livenessImageInfos.compactMap { $0 }
            )
          }
          guard let smartSelfieImage,
                smartSelfieLivenessImages.count == Constants.numLivenessImages
          else {
            throw SmileIDError.unknown("Selfie capture failed")
          }

          let response = try await self.performSmartSelfieNetworkCall(
            isEnroll: self.isEnroll,
            authResponse: authResponse,
            smartSelfieImage: smartSelfieImage,
            smartSelfieLivenessImages: smartSelfieLivenessImages
          )
          self.apiResponse = response
        }

        do {
          try LocalStorage.moveToSubmittedJobs(jobId: self.jobId)
          self.selfieImage = try LocalStorage.getFileByType(
            jobId: jobId,
            fileType: FileType.selfie,
            submitted: true
          )
          self.livenessImages =
            try LocalStorage.getFilesByType(
              jobId: jobId,
              fileType: FileType.liveness,
              submitted: true
            ) ?? []
        } catch {
          debug("Error moving job to submitted directory: \(error)", category: "SelfieViewModel")
          self.error = error
        }
        resetNetworkRetries()
        updateOnMain { self.processingState = .success }
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
            self.livenessImages =
              try LocalStorage.getFilesByType(
                jobId: jobId,
                fileType: FileType.liveness,
                submitted: true
              ) ?? []
          }
        } catch {
          debug("Error moving job to submitted directory: \(error)", category: "SelfieViewModel")
          self.error = error
          return
        }
        if SmileID.allowOfflineMode,
           SmileIDError.isNetworkFailure(error: error) {
          updateOnMain {
            self.errorMessageRes = "Offline.Message"
            self.processingState = .success
          }
        } else {
          debug("Error submitting job: \(error)", category: "SelfieViewModel")
          let (errorMessageRes, errorMessage) = toErrorMessage(
            error: error
          )
          self.error = error
          self.errorMessageRes = errorMessageRes
          self.errorMessage = errorMessage
          updateOnMain { self.processingState = .error }
        }
      } catch {
        debug("Error submitting job: \(error)", category: "SelfieViewModel")
        self.error = error
        updateOnMain { self.processingState = .error }
      }
    }
  }

  private func performSmartSelfieNetworkCall(
    isEnroll: Bool,
    authResponse: AuthenticationResponse,
    smartSelfieImage: MultipartBody,
    smartSelfieLivenessImages: [MultipartBody]
  ) async throws -> SmartSelfieResponse {
    if isEnroll {
      return try await SmileID.api.doSmartSelfieEnrollment(
        signature: authResponse.signature,
        timestamp: authResponse.timestamp,
        selfieImage: smartSelfieImage,
        livenessImages: smartSelfieLivenessImages,
        userId: userId,
        partnerParams: extraPartnerParams,
        callbackUrl: SmileID.callbackUrl,
        sandboxResult: nil,
        allowNewEnroll: allowNewEnroll,
        failureReason: nil
      )
    } else {
      return try await SmileID.api.doSmartSelfieAuthentication(
        signature: authResponse.signature,
        timestamp: authResponse.timestamp,
        userId: userId,
        selfieImage: smartSelfieImage,
        livenessImages: smartSelfieLivenessImages,
        partnerParams: extraPartnerParams,
        callbackUrl: SmileID.callbackUrl,
        sandboxResult: nil,
        failureReason: nil
      )
    }
  }
}
