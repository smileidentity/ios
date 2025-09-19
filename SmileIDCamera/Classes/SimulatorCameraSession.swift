#if targetEnvironment(simulator)

  import AVFoundation
  import CoreVideo
  import UIKit

  public final class SimulatorCameraSession: CameraSessionProtocol {
    public var previewView: CameraPreviewView? {
      didSet {
        guard oldValue !== previewView else { return }
        updatePreviewLayer()
      }
    }

    private let images: [UIImage]
    private var currentImageIndex: Int = 0
    private var timer: Timer?
    private let sessionQueue = DispatchQueue(label: "com.smileid.camera.simulator")
    private weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private let videoOuput = AVCaptureVideoDataOutput()
    private lazy var connection = AVCaptureConnection(inputPorts: [], output: videoOuput)

    public init(images: [UIImage]) {
      self.images = images
    }

    public func configure(
      with configuration: CameraConfiguration,
      delegate: any AVCaptureVideoDataOutputSampleBufferDelegate,
      completionQueue: DispatchQueue,
      completion: @escaping (Result<Void, any Error>) -> Void
    ) {
      sessionQueue.async { [weak self] in
        guard let self else { return }
        self.delegate = delegate
        self.connection.videoOrientation = configuration.initialOrientation
        guard !self.images.isEmpty else {
          completionQueue.async { completion(.failure(CameraError.captureDeviceUnavailable)) }
          return
        }
        completionQueue.async {
          completion(.success(()))
        }
      }
    }

    public func setVideoOrientation(
      _ orientation: AVCaptureVideoOrientation
    ) {
      connection.videoOrientation = orientation
    }

    public func toggleCamera(
      to _: CameraDevicePosition,
      completionQueue: DispatchQueue,
      completion: @escaping (Result<Void, any Error>
      ) -> Void) {
      completionQueue.async {
        completion(.success(()))
      }
    }

    public func toggleTorch() {}

    public func deviceProperties() -> CameraDeviceProperties? { nil }

    public func startRunning(
      completionQueue: DispatchQueue,
      completion: @escaping () -> Void
    ) {
      sessionQueue.async { [weak self] in
        guard let self else { return }
        DispatchQueue.main.async {
          self.startTimer()
          completionQueue.async { completion() }
        }
      }
    }

    public func stopRunning(
      completionQueue: DispatchQueue,
      completion: @escaping () -> Void
    ) {
      sessionQueue.async { [weak self] in
        guard let self else { return }
        DispatchQueue.main.async {
          self.timer?.invalidate()
          self.timer = nil
          completionQueue.async { completion() }
        }
      }
    }

    private func startTimer() {
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        self?.emitNextFrame()
      }
      updatePreviewLayer()
    }

    private func emitNextFrame() {
      guard !images.isEmpty else { return }
      let image = images[currentImageIndex % images.count]
      currentImageIndex += 1

      guard let buffer = image.pixelBufferSampleBuffer() else { return }
      delegate?.captureOutput?(videoOuput, didOutput: buffer, from: connection)
      updatePreviewLayer(with: image)
    }

    private func updatePreviewLayer(with image: UIImage? = nil) {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        let displayImage = image ?? self.images.first
        self.previewView?.layer.contents = displayImage?.cgImage
        self.previewView?.layer.contentsGravity = .resizeAspectFill
      }
    }
  }

#endif
