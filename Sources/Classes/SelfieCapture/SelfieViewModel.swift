import ARKit
import Combine
import Foundation
import Vision

// MARK: - View Model

public final class SelfieViewModel: ObservableObject, ARKitSmileDelegate {
  // MARK: - Constants

  private enum Constants {
    // min spacing between frames we analyse
    static let intraImageMinDelay: TimeInterval = 0.35
    // reset if user absent > 3 s
    static let noFaceResetDelay: TimeInterval = 3

    // Vision quality & geometry thresholds
    static let faceCaptureQualityThreshold: Float = 0.25
    static let minFaceCenteredThreshold = 0.1
    static let maxFaceCenteredThreshold = 0.9
    static let minFaceAreaThreshold = 0.125 // ~12 % of frame
    static let maxFaceAreaThreshold = 0.25 // ~25 % of frame
    static let faceRotationThreshold = 0.03 // radians
    static let faceRollThreshold = 0.025

    // Tracker tuning
    // below this, treat as lost
    static let faceTrackerConfidenceThreshold: Float = 0.40
    // tolerate N empty frames before reset
    static let faceLostMaxFrames = 10

    // Capture counts
    static let numLivenessImages = 7
    // liveness + final selfie
    static var numTotalSteps: Int { numLivenessImages + 1 }

    // Resize targets (px height)
    static let livenessImageSize = 320
    static let selfieImageSize = 640
  }

  // MARK: - UI string keys

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

  // MARK: - Immutable configuration (passed via init)

  private let isEnroll: Bool
  private let userId: String
  private let jobId: String
  private let allowNewEnroll: Bool
  private let skipApiSubmission: Bool
  private let extraPartnerParams: [String: String]

  // MARK: - Dependencies

  private let metadata: Metadata = .shared
  private let faceDetector = FaceDetector()

  // MARK: - Timing / general state

  private var captureDuration = MonotonicTime()
  private var networkRetries = 0
  private var selfieCaptureRetries = 0
  private var hasRecordedOrientationAtCaptureStart = false
  private var lastAutoCaptureTime = Date()

  // MARK: - Vision face-tracking state

  private let faceTracker = VisionFaceTracker(
    confidenceThreshold: Constants.faceTrackerConfidenceThreshold,
    maxLostFrames: Constants.faceLostMaxFrames
  )

  // Previous head-pose samples (for rotation diversity gate)
  private var previousHeadRoll = Double.infinity
  private var previousHeadPitch = Double.infinity
  private var previousHeadYaw = Double.infinity

  // MARK: - ARKit smile signal

  private var isSmiling = false

  // MARK: - Camera

  var cameraManager = CameraManager(orientation: .portrait)
  var shouldAnalyzeImages = true
  var currentlyUsingArKit: Bool {
    ARFaceTrackingConfiguration.isSupported && !useBackCamera
  }

  // MARK: - Capture artefacts

  var selfieImage: URL?
  var livenessImages: [URL] = []
  var apiResponse: SmartSelfieResponse?
  var error: Error?

  // MARK: - Combine plumbing

  private let arKitFramePublisher = PassthroughSubject<CVPixelBuffer?, Never>()
  private var subscribers = Set<AnyCancellable>()

  // MARK: - UI-published properties

  @Published var unauthorizedAlert: AlertState?
  @Published var directive: String = Directive.start.rawValue
  @Published var errorMessageRes: String?
  @Published var errorMessage: String?
  @Published private(set) var processingState: ProcessingState?
  @Published private(set) var selfieToConfirm: Data?
  @Published var captureProgress: Double = 0
  @Published var useBackCamera = false {
    didSet { switchCamera() }
  }

  // MARK: - Init

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

    configureCameraSession()
    bindCameraAuthorization()
    bindFrameStream()

    // Add initial metadata key for camera selection
    metadata.addMetadata(
      key: .selfieImageOrigin,
      value: CameraFacingValue.frontCamera.rawValue
    )
  }

  // MARK: - Setup helpers

  private func configureCameraSession() {
    if cameraManager.session.canSetSessionPreset(.vga640x480) {
      cameraManager.session.sessionPreset = .vga640x480
    }
  }

  /// Surface alert if user revokes camera permission
  private func bindCameraAuthorization() {
    cameraManager.$status
      .receive(on: DispatchQueue.main)
      .filter { $0 == .unauthorized }
      .map { _ in AlertState.cameraUnauthorized }
      .sink { [weak self] alert in self?.unauthorizedAlert = alert }
      .store(in: &subscribers)
  }

  /// Merge camera-stream & optional ARKit frames, throttle, and analyse
  private func bindFrameStream() {
    cameraManager.sampleBufferPublisher
      .receive(on: DispatchQueue.main)
      .merge(with: arKitFramePublisher)
      .throttle(
        for: .milliseconds(Int(Constants.intraImageMinDelay * 1000)),
        scheduler: DispatchQueue.global(qos: .userInitiated),
        latest: true
      )
      .dropFirst(5) // allow ~2 s for user to position themselves
      .compactMap { $0 }
      .sink { [weak self] buffer in
        self?.analyzeImage(image: buffer)
      }
      .store(in: &subscribers)
  }

  // MARK: - Per-frame analysis pipeline

  func analyzeImage(image pixelBuffer: CVPixelBuffer) {
    recordCaptureStartIfNeeded()

    // gate based on min spacing
    guard shouldAnalyzeImages,
          Date().timeIntervalSince(lastAutoCaptureTime) >= Constants.intraImageMinDelay
    else { return }

    // Try to update an existing Vision tracker *before* we run heavy detection.
    switch faceTracker.update(with: pixelBuffer) {
    case .tracked(let face):
      // successful update – feed synthetic VNFaceObservation downstream
      handleDetectionResults(
        [face],
        elapsed: Date().timeIntervalSince(lastAutoCaptureTime),
        image: pixelBuffer
      )
      return
    case .lost(let exceeded) where exceeded:
      // Tracker lost beyond tolerance – reset UI and continue with detection fallback
      resetTrackerAndUI()
    case .lost, .noTracker:
      break // fall through to face detection
    }

    // Fallback to full face-detection when no active tracker.
    do {
      try faceDetector.detect(imageBuffer: pixelBuffer) { [weak self] req, err in
        guard let self else { return }
        if let err {
          debug(
            "Face detection error: \(err.localizedDescription)",
            category: "SelfieViewModel"
          )
          self.error = err
          return
        }
        guard let faces = req.results as? [VNFaceObservation] else {
          debug("Unexpected Vision result type", category: "SelfieViewModel")
          return
        }
        self.handleDetectionResults(
          faces,
          elapsed: Date().timeIntervalSince(self.lastAutoCaptureTime),
          image: pixelBuffer
        )
      }
    } catch {
      debug(
        "Vision request setup error: \(error.localizedDescription)",
        category: "SelfieViewModel"
      )
    }
  }

  // MARK: - Vision results handling

  private func handleDetectionResults(
    _ faces: [VNFaceObservation],
    elapsed: TimeInterval,
    image: CVPixelBuffer
  ) {
    // (Re)-start or cancel the tracker based on how many faces we see.
    switch faces.count {
    case 1:
      if !faceTracker.isTracking {
        faceTracker.startTracking(from: faces[0])
      }
    default:
      // multiple or zero faces – abandon tracker to force fresh detection next frame.
      faceTracker.cancelTracking()
    }

    // Validation cascade
    if faces.isEmpty {
      updateDirective(.unableToDetectFace)
      // If the face has been gone for a while, reset entire capture flow.
      if elapsed > Constants.noFaceResetDelay { resetTrackerAndUI() }
      return
    }

    if faces.count > 1 {
      updateDirective(.multipleFaces)
      return
    }

    guard let face = faces.first else { return }
    guard validateFacePosition(face),
          validateFaceArea(face),
          validateFaceQuality(face)
    else { return }

    let requireSmile = livenessImages.count > Constants.numLivenessImages / 2
    updateDirective(requireSmile ? .smile : .capturing)

    if requireSmile, currentlyUsingArKit, !isSmiling {
      debug("Awaiting smile signal from ARKit", category: "SelfieViewModel")
      return
    }

    // After UI directive switches to "Capturing", ensure head rotation variety
    guard hasFaceRotatedEnough(face: face) else { return }

    // Perform Capture
    lastAutoCaptureTime = Date()
    let orientation = getUprightOrientation()
    do {
      try captureFrame(image, orientation: orientation)
    } catch {
      debug(
        "Image save error: \(error.localizedDescription)",
        category: "SelfieViewModel"
      )
      self.error = error
      updateOnMain { self.processingState = .error }
    }
  }

  // MARK: - Validation helpers

  private func validateFacePosition(_ face: VNFaceObservation) -> Bool {
    let box = face.boundingBox
    guard box.minX >= Constants.minFaceCenteredThreshold,
          box.minY >= Constants.minFaceCenteredThreshold,
          box.maxX <= Constants.maxFaceCenteredThreshold,
          box.maxY <= Constants.maxFaceCenteredThreshold
    else {
      updateDirective(.putFaceInOval)
      return false
    }
    return true
  }

  private func validateFaceArea(_ face: VNFaceObservation) -> Bool {
    let ratio = face.boundingBox.width * face.boundingBox.height
    if ratio < Constants.minFaceAreaThreshold {
      updateDirective(.moveCloser)
      return false
    }
    if ratio > Constants.maxFaceAreaThreshold {
      updateDirective(.moveFarther)
      return false
    }
    return true
  }

  private func validateFaceQuality(_ face: VNFaceObservation) -> Bool {
    if let quality = face.faceCaptureQuality,
       quality < Constants.faceCaptureQualityThreshold {
      updateDirective(.quality)
      return false
    }
    return true
  }

  // MARK: - Capture helpers (resizing, disk I/O)

  private func captureFrame(
    _ pixelBuffer: CVPixelBuffer,
    orientation: CGImagePropertyOrientation
  ) throws {
    if livenessImages.count < Constants.numLivenessImages {
      // Save liveness frame
      guard
        let data = ImageUtils.resizePixelBufferToHeight(
          pixelBuffer,
          height: Constants.livenessImageSize,
          orientation: orientation
        )
      else { throw SmileIDError.unknown("Failed to resize liveness image") }

      let url = try LocalStorage.createLivenessFile(jobId: jobId, livenessFile: data)
      livenessImages.append(url)
      updateCaptureProgress()
    } else {
      // Final selfie
      shouldAnalyzeImages = false
      guard
        let data = ImageUtils.resizePixelBufferToHeight(
          pixelBuffer,
          height: Constants.selfieImageSize,
          orientation: orientation
        )
      else { throw SmileIDError.unknown("Failed to resize selfie image") }

      selfieImage = try LocalStorage.createSelfieFile(jobId: jobId, selfieFile: data)
      recordCaptureEnd()
      updateOnMain {
        self.captureProgress = 1
        self.selfieToConfirm = data
      }
    }
  }

  private func updateCaptureProgress() {
    updateOnMain {
      self.captureProgress =
        Double(self.livenessImages.count) / Double(Constants.numTotalSteps)
    }
  }

  // MARK: - Face rotation diversity gate

  func hasFaceRotatedEnough(face: VNFaceObservation) -> Bool {
    guard let roll = face.roll?.doubleValue,
          let yaw = face.yaw?.doubleValue else { return true }

    var pitchMoved = false
    if #available(iOS 15, *),
       let pitch = face.pitch?.doubleValue {
      pitchMoved = abs(pitch - previousHeadPitch) > Constants.faceRotationThreshold
      previousHeadPitch = pitch
    }

    let rollDelta = abs(roll - previousHeadRoll)
    let yawDelta = abs(yaw - previousHeadYaw)
    previousHeadRoll = roll
    previousHeadYaw = yaw

    return pitchMoved
      || rollDelta > Constants.faceRollThreshold
      || yawDelta > Constants.faceRotationThreshold
  }

  // MARK: - Helpers (metadata, UI, tracker reset)

  private func recordCaptureStartIfNeeded() {
    guard !hasRecordedOrientationAtCaptureStart else { return }
    metadata.addMetadata(key: .deviceOrientation)
    hasRecordedOrientationAtCaptureStart = true
    captureDuration.startTime()
  }

  private func recordCaptureEnd() {
    metadata.addMetadata(key: .deviceOrientation)
    metadata.addMetadata(
      key: .selfieCaptureDuration,
      value: captureDuration.elapsedTime().milliseconds()
    )
  }

  private func updateDirective(_ directive: Directive) {
    updateOnMain { self.directive = directive.rawValue }
  }

  /// Clears Vision tracker, counters, progress & UI-state.
  private func resetTrackerAndUI() {
    debug(
      "Resetting capture due to prolonged no-face / tracker loss",
      category: "SelfieViewModel"
    )
    faceTracker.cancelTracking()
    resetCaptureUIState()
    selfieImage = nil
    livenessImages.removeAll()
    cleanUpSelfieCapture()
  }

  private func resetCaptureUIState() {
    updateOnMain {
      self.captureProgress = 0
      self.selfieToConfirm = nil
      self.processingState = nil
    }
  }

  // MARK: - Orientation helper

  private func getUprightOrientation() -> CGImagePropertyOrientation {
    let deviceOrientation = UIDevice.current.orientation
    if currentlyUsingArKit {
      switch deviceOrientation {
      case .portrait: return .right
      case .portraitUpsideDown: return .left
      case .landscapeLeft: return .up
      case .landscapeRight: return .down
      default: return .right
      }
    } else {
      switch deviceOrientation {
      case .portrait: return .up
      case .portraitUpsideDown: return .down
      case .landscapeLeft: return .right
      case .landscapeRight: return .left
      default: return .up
      }
    }
  }

  // MARK: - Main-thread helper

  @inline(__always)
  private func updateOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  // MARK: - ARKitSmileDelegate

  public func onSmiling(isSmiling flag: Bool) { isSmiling = flag }
  public func onARKitFrame(frame: ARFrame) { arKitFramePublisher.send(frame.capturedImage) }

  // MARK: - Camera switching

  func switchCamera() {
    cameraManager.switchCamera(to: useBackCamera ? .back : .front)
    metadata.removeMetadata(key: .selfieImageOrigin)
    let newFacing = useBackCamera ? CameraFacingValue.backCamera : .frontCamera
    metadata.addMetadata(key: .selfieImageOrigin, value: newFacing.rawValue)
  }

  // MARK: - UI: retry / rejection

  public func onSelfieRejected() {
    resetTrackerAndUI()
    shouldAnalyzeImages = true
    selfieCaptureRetries += 1

    // clean metadata keys from previous attempt
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
      debug(error.localizedDescription, category: "SelfieViewModel")
    }
  }

  func onRetry() {
    if selfieImage != nil, livenessImages.count == Constants.numLivenessImages {
      incrementNetworkRetries()
      submitJob()
    } else {
      selfieCaptureRetries += 1
      shouldAnalyzeImages = true
      DispatchQueue.main.async { self.processingState = nil }
    }
  }

  // MARK: – Delegate callback

  public func onFinished(callback: SmartSelfieResultDelegate) {
    if let error {
      callback.didError(error: error)
    } else if let selfieImage,
              livenessImages.count == Constants.numLivenessImages {
      callback.didSucceed(
        selfieImage: selfieImage,
        livenessImages: livenessImages,
        apiResponse: apiResponse
      )
    } else {
      callback.didError(error: SmileIDError.unknown("Unknown error"))
    }
  }

  // MARK: - Settings + metadata helpers (unchanged)

  func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

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
