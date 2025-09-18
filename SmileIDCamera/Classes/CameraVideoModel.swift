import AVFoundation
import CoreMedia
import Foundation

public final class CameraViewModel: NSObject, ObservableObject {
  @Published public private(set) var isAuthorized: Bool = false
  @Published public private(set) var isSessionRunning = false
  @Published public private(set) var lastError: Error?
  @Published public private(set) var deviceProperties: CameraDeviceProperties?
  @Published public private(set) var lastSampleBuffer: CMSampleBuffer?

  public let session: CameraSessionProtocol

  private let authorizationService: CameraPermissionsProtocol
  private let settingsNavigator: AppSettingsManager
  private let configuration: CameraConfiguration
  private let callbackQueue = DispatchQueue(label: "com.smileid.camera.callback")
  private var currentPosition: CameraDevicePosition

  public init(
    session: CameraSessionProtocol,
    authorizationService: CameraPermissionsProtocol,
    settingsNavigator: AppSettingsManager,
    configuration: CameraConfiguration
  ) {
    self.session = session
    self.authorizationService = authorizationService
    self.settingsNavigator = settingsNavigator
    self.configuration = configuration
    self.currentPosition = configuration.initialPosition
    super.init()
  }

  public func onAppear() {
    requestAccessIfNeeded()
  }

  public func onDisappear() {
    session.stopRunning(completionQueue: .main) { [weak self] in
      self?.isSessionRunning = false
    }
  }

  public func setOrientation(_ orientation: AVCaptureVideoOrientation) {
    session.setVideoOrientation(orientation)
  }

  public func toggleCamera() {
    let nextPosition: CameraDevicePosition = (currentPosition == .back) ? .front : .back
    session.toggleCamera(to: nextPosition, completionQueue: .main) { [weak self] result in
      guard let self else { return }
      switch result {
      case .success:
        self.currentPosition = nextPosition
      case .failure(let error):
        self.lastError = error
      }
    }
  }

  public func toggleTorch() {
    session.toggleTorch()
  }

  public func openSettings() {
    guard settingsNavigator.canOpenAppSettings else { return }
    settingsNavigator.openAppSettings()
  }

  func clearLastError() {
    self.lastError = nil
  }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
  public func captureOutput(
    _: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from _: AVCaptureConnection
  ) {
    callbackQueue.async { [weak self] in
      guard let self else { return }
      let properties = self.session.deviceProperties()
      DispatchQueue.main.async {
        self.deviceProperties = properties
        self.lastSampleBuffer = sampleBuffer
      }
    }
  }
}

private extension CameraViewModel {
  func requestAccessIfNeeded() {
    authorizationService.requestAccess(queue: .main) { [weak self] granted in
      guard let self else { return }
      guard let granted else {
        self.lastError = CameraError.permissionDenied
        return
      }

      self.isAuthorized = granted
      if granted {
        self.configureSessionIfNeeded()
      } else {
        self.lastError = CameraError.permissionDenied
      }
    }
  }

  func configureSessionIfNeeded() {
    session.configure(
      with: configuration,
      delegate: self,
      completionQueue: .main
    ) { [weak self] result in
      guard let self else { return }
      switch result {
      case .success:
        self.startSession()
      case .failure(let error):
        self.lastError = error
      }
    }
  }

  func startSession() {
    session.startRunning(completionQueue: .main) { [weak self] in
      self?.isSessionRunning = true
    }
  }
}
