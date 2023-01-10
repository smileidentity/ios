import Foundation
import AVFoundation
import SwiftUI

class CameraManager: ObservableObject {

    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }

    static let shared = CameraManager()

    @Published var error: CameraError?
    @Environment(\.isPreview) var isPreview

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.smileidentity.ios")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var status = Status.unconfigured

    private init() {
        guard !isPreview else { return }
        configure()
    }

    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }

    private func checkPermissions() {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .notDetermined:
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { authorized in
          if !authorized {
            self.status = .unauthorized
            self.set(error: .deniedAuthorization)
          }
          self.sessionQueue.resume()
        }
      case .restricted:
        status = .unauthorized
        set(error: .restrictedAuthorization)
      case .denied:
        status = .unauthorized
        set(error: .deniedAuthorization)
      case .authorized:
        break
      @unknown default:
        status = .unauthorized
        set(error: .unknownAuthorization)
      }
    }

    private func configureCaptureSession() {
        guard status == .unconfigured else {
            return
        }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        let device = AVCaptureDevice.default(
          .builtInWideAngleCamera,
          for: .video,
          position: .front)
        guard let camera = device else {
          set(error: .cameraUnavailable)
          status = .failed
          return
        }

        do {
          let cameraInput = try AVCaptureDeviceInput(device: camera)
          if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
          } else {
            set(error: .cannotAddInput)
            status = .failed
            return
          }
        } catch {
          set(error: .createCaptureInput(error))
          status = .failed
          return
        }

        if session.canAddOutput(videoOutput) {
          session.addOutput(videoOutput)

          videoOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

          let videoConnection = videoOutput.connection(with: .video)
          videoConnection?.videoOrientation = .portrait
        } else {
          set(error: .cannotAddOutput)
          status = .failed
          return
        }
        status = .configured
    }

    private func configure() {
        checkPermissions()
        sessionQueue.async {
          self.configureCaptureSession()
          self.session.startRunning()
        }
    }

    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
             queue: DispatchQueue) {
      sessionQueue.async {
        self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
      }
    }
}
