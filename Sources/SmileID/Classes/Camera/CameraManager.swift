import Foundation
import AVFoundation
import SwiftUI

protocol CameraManageable: AnyObject  {
    func switchCamera(to position: AVCaptureDevice.Position)
    func capturePhoto()
    func pauseSession()
    func resumeSession()
    var sampleBufferPublisher: Published<CVPixelBuffer?>.Publisher {get}
    var capturedImagePublisher: Published<UIImage?>.Publisher {get}
    var session: AVCaptureSession { get }
    var cameraPositon: AVCaptureDevice.Position? {get}
}

class CameraManager: NSObject, ObservableObject, CameraManageable {

    enum Mode {
        case selfie
        case document
    }

    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }

    @Published var error: CameraError?
    @Environment(\.isPreview) var isPreview
    @Published var sampleBuffer: CVPixelBuffer?
    @Published var capturedImage: UIImage?
    var sampleBufferPublisher: Published<CVPixelBuffer?>.Publisher { $sampleBuffer }
    var capturedImagePublisher: Published<UIImage?>.Publisher { $capturedImage }
    let videoOutputQueue = DispatchQueue(label: "com.smileid.videooutput",
                                         qos: .userInitiated,
                                         attributes: [],
                                         autoreleaseFrequency: .workItem)

    var session = AVCaptureSession()
    var cameraPositon: AVCaptureDevice.Position? {
        if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
            return currentInput.device.position
        }
        return nil
    }

    private let sessionQueue = DispatchQueue(label: "com.smileid.ios")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var status = Status.unconfigured
    private var mode: Mode

    init(mode: Mode) {
        self.mode = mode
        super.init()
        set(self, queue: videoOutputQueue)
    }

    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }

    private func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
                     queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
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

    private func addCameraInput(position: AVCaptureDevice.Position) {
        guard let camera = getCameraForPosition(position) else {
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
            }
        } catch {
            set(error: .createCaptureInput(error))
            status = .failed
        }
    }

    private func getCameraForPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        switch position {
        case .front:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        case .back:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        default:
            return nil
        }
    }

    private func configureVideoOutput() {
        session.removeOutput(videoOutput)
        session.removeOutput(photoOutput)
        if session.canAddOutput(videoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            session.addOutput(videoOutput)
            videoOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            if mode == .selfie {
                let videoConnection = videoOutput.connection(with: .video)
                videoConnection?.videoOrientation = .portrait
            }
        } else {
            set(error: .cannotAddOutput)
            status = .failed
        }
    }

    func switchCamera(to position: AVCaptureDevice.Position) {
        self.checkPermissions()
        sessionQueue.async { [self] in
            if !self.session.isRunning {
                if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                    self.session.removeInput(currentInput)
                }
                self.addCameraInput(position: position)
                self.configureVideoOutput()
                session.startRunning()
            } else {
                self.session.beginConfiguration()
                if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                    self.session.removeInput(currentInput)
                }
                self.addCameraInput(position: position)
                self.configureVideoOutput()
                self.session.commitConfiguration()
            }
        }
    }

    func pauseSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func resumeSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    internal func capturePhoto() {
        guard let connection = photoOutput.connection(with: .video), connection.isEnabled, connection.isActive else {
            return
        }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        self.sampleBuffer = imageBuffer
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            return
        }
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            self.capturedImage  = image
        } else {
            print(error?.localizedDescription)
            return
        }
    }
}
