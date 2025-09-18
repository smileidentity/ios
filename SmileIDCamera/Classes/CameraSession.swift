import AVFoundation
import CoreMedia
import Foundation

public final class CameraSession: NSObject, CameraSessionProtocol {
  public var previewView: CameraPreviewView? {
    didSet {
      guard oldValue !== previewView else { return }
      // Remove captureSession from previous view and add it to new one
      oldValue?.setCaptureSession(nil, queue: sessionQueue)
      previewView?.setCaptureSession(session, queue: sessionQueue)
    }
  }

  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "com.smileid.camera-session")
  private let sessionQueueKey = DispatchSpecificKey<Void>()
  private var videoInput: AVCaptureDeviceInput?
  private var videoOuput: AVCaptureVideoDataOutput?
  private var videoConnection: AVCaptureConnection?
  private var setupResult: Result<Void, Error>?
  private var torchManager: TorchManager?
  private var currentOrientation: AVCaptureVideoOrientation = .portrait
  private var cachedConfiguration: CameraConfiguration?

  override public init() {
    super.init()
    sessionQueue.setSpecific(key: sessionQueueKey, value: ())
  }

  public func configure(
    with configuration: CameraConfiguration,
    delegate: any AVCaptureVideoDataOutputSampleBufferDelegate,
    completionQueue: DispatchQueue,
    completion: @escaping (Result<Void, any Error>) -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      if let setupResult = self.setupResult {
        completionQueue.async { completion(setupResult) }
        return
      }

      do {
        try self.configureSession(configuration: configuration, delegate: delegate)
        self.cachedConfiguration = configuration
        self.setupResult = .success(())
        completionQueue.async { completion(.success(())) }
      } catch {
        self.setupResult = .failure(error)
        completionQueue.async { completion(.failure(error)) }
      }
    }
  }

  public func setVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
    currentOrientation = orientation
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.videoConnection?.videoOrientation = orientation
      self.previewView?.videoPreviewLayer.connection?.videoOrientation = orientation
    }
  }

  public func toggleCamera(
    to position: CameraDevicePosition,
    completionQueue: DispatchQueue,
    completion: @escaping (Result<Void, any Error>) -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      do {
        try self.reconfigureInput(position: position)
        completionQueue.async { completion(.success(())) }
      } catch {
        completionQueue.async { completion(.failure(error)) }
      }
    }
  }

  public func toggleTorch() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      self.torchManager?.toggle()
    }
  }

  public func deviceProperties() -> CameraDeviceProperties? {
    if DispatchQueue.getSpecific(key: sessionQueueKey) != nil {
      return currentDeviceProperties()
    } else {
      return sessionQueue.sync {
        currentDeviceProperties()
      }
    }
  }

  public func startRunning(
    completionQueue: DispatchQueue,
    completion: @escaping () -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      defer { completionQueue.async { completion() } }

      guard case .success? = self.setupResult else { return }
      guard !self.session.isRunning else { return }
      self.session.startRunning()
    }
  }

  public func stopRunning(
    completionQueue: DispatchQueue,
    completion: @escaping () -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      defer { completionQueue.async { completion() } }

      guard case .success? = self.setupResult else { return }
      guard self.session.isRunning else { return }
      self.session.stopRunning()
    }
  }
}

// MARK: - Private Helpers

private extension CameraSession {
  func configureSession(
    configuration: CameraConfiguration,
    delegate: AVCaptureVideoDataOutputSampleBufferDelegate
  ) throws {
    session.beginConfiguration()
    defer { session.commitConfiguration() }

    session.sessionPreset = configuration.sessionPreset
    try configureInput(position: configuration.initialPosition)
    try configureOutput(configuration: configuration, delegate: delegate)
  }

  func configureInput(position: CameraDevicePosition) throws {
    for input in session.inputs {
      session.removeInput(input)
    }

    let deviceInput = try makeDeviceInput(for: position)

    guard session.canAddInput(deviceInput) else {
      throw CameraError.configurationFailed
    }

    session.addInput(deviceInput)
    videoInput = deviceInput
    torchManager = TorchManager(device: deviceInput.device)
  }

  func reconfigureInput(position: CameraDevicePosition) throws {
    session.beginConfiguration()
    defer { session.commitConfiguration() }

    try configureInput(position: position)

    if let config = cachedConfiguration {
      try applyFocusIfNeeded(configuration: config)
    }

    if let output = videoOuput,
       let connection = output.connection(with: .video) {
      connection.videoOrientation = currentOrientation
      videoConnection = connection
    }
  }

  func configureOutput(
    configuration: CameraConfiguration,
    delegate: AVCaptureVideoDataOutputSampleBufferDelegate
  ) throws {
    if let existingOutput = videoOuput {
      session.removeOutput(existingOutput)
    }

    let output = AVCaptureVideoDataOutput()
    output.videoSettings = configuration.outputSettings
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(delegate, queue: sessionQueue)

    guard session.canAddOutput(output) else {
      throw CameraError.configurationFailed
    }

    session.addOutput(output)
    videoOuput = output

    let connection = output.connection(with: .video)
    connection?.videoOrientation = configuration.initialOrientation
    videoConnection = connection
    currentOrientation = configuration.initialOrientation

    try applyFocusIfNeeded(configuration: configuration)
  }

  func makeDeviceInput(for position: CameraDevicePosition) throws -> AVCaptureDeviceInput {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: position.preferredDeviceTypes,
      mediaType: .video,
      position: position.avPosition
    )

    guard let device = discovery.devices.first else {
      throw CameraError.captureDeviceUnavailable
    }

    return try AVCaptureDeviceInput(device: device)
  }

  func applyFocusIfNeeded(configuration: CameraConfiguration) throws {
    guard let focusMode = configuration.focusMode,
          let device = videoInput?.device else {
      return
    }

    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }

    if device.isFocusModeSupported(focusMode) {
      device.focusMode = focusMode
    }

    if device.isAutoFocusRangeRestrictionSupported {
      device.autoFocusRangeRestriction = configuration.autoFocusRestriction
    }

    if let point = configuration.focusPoint,
       device.isFocusPointOfInterestSupported {
      if device.isSmoothAutoFocusSupported {
        device.isSmoothAutoFocusEnabled = true
      }
      device.focusPointOfInterest = point
    }

    if device.isLowLightBoostSupported {
      device.automaticallyEnablesLowLightBoostWhenAvailable = true
    }
  }

  func currentDeviceProperties() -> CameraDeviceProperties? {
    guard let device = videoInput?.device else {
      return nil
    }

    return CameraDeviceProperties(
      exposureDuration: device.exposureDuration,
      deviceType: device.deviceType,
      isVirtualDevice: device.isVirtualDevice,
      lensPosition: device.lensPosition,
      iso: device.iso,
      isAdjustingFocus: device.isAdjustingFocus
    )
  }
}
