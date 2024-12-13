import AVFoundation
import Foundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {

    enum Orientation {
        case portrait
        case landscape
    }

    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }

    @Environment(\.isPreview) var isPreview
    @Published var error: CameraError?
    @Published var sampleBuffer: CVPixelBuffer?
    @Published var capturedImage: Data?

    var sampleBufferPublisher: Published<CVPixelBuffer?>.Publisher {
        $sampleBuffer
    }
    var capturedImagePublisher: Published<Data?>.Publisher { $capturedImage }
    let videoOutputQueue = DispatchQueue(
        label: "com.smileidentity.videooutput",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )

    var session = AVCaptureSession()
    var cameraPosition: AVCaptureDevice.Position? {
        (session.inputs.first as? AVCaptureDeviceInput)?.device.position
    }

    private(set) var cameraName: String?

    // Used to queue and then resume tasks while waiting for Camera permissions
    private let sessionQueue = DispatchQueue(label: "com.smileidentity.ios")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    @Published private(set) var status = Status.unconfigured
    private var orientation: Orientation

    init(orientation: Orientation) {
        self.orientation = orientation
        super.init()
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(
                self, queue: self.videoOutputQueue)
        }
        checkPermissions()
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

    private func addCameraInput(position: AVCaptureDevice.Position) {
        guard let camera = getCameraForPosition(position) else {
            set(error: .cameraUnavailable)
            status = .failed
            return
        }

        getCameraName(for: camera)

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

    private func getCameraName(for camera: AVCaptureDevice) {
        var manufacturer: String
        if #available(iOS 14.0, *) {
            manufacturer = camera.manufacturer
        } else {
            manufacturer = "Apple Inc."
        }
        cameraName =
            "\(manufacturer) \(camera.localizedName) \(camera.deviceType.rawValue)"
    }

    private func getCameraForPosition(_ position: AVCaptureDevice.Position)
        -> AVCaptureDevice? {
        switch position {
        case .front:
            return AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front)
        case .back:
            return AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back)
        default:
            return AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front)
        }
    }

    private func configureVideoOutput() {
        session.removeOutput(videoOutput)
        session.removeOutput(photoOutput)
        if session.canAddOutput(videoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            session.addOutput(videoOutput)
            videoOutput.videoSettings =
                [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        kCVPixelFormatType_32BGRA
                ]
            if orientation == .portrait {
                let videoConnection = videoOutput.connection(with: .video)
                videoConnection?.videoOrientation = .portrait
            }
        } else {
            set(error: .cannotAddOutput)
            status = .failed
        }
    }

    func switchCamera(to position: AVCaptureDevice.Position) {
        checkPermissions()
        sessionQueue.async { [self] in
            if !session.isRunning {
                if let currentInput = session.inputs.first
                    as? AVCaptureDeviceInput {
                    session.removeInput(currentInput)
                }
                addCameraInput(position: position)
                configureVideoOutput()
                session.startRunning()
            } else {
                session.beginConfiguration()
                if let currentInput = session.inputs.first
                    as? AVCaptureDeviceInput {
                    session.removeInput(currentInput)
                }
                addCameraInput(position: position)
                configureVideoOutput()
                session.commitConfiguration()
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
        guard let connection = photoOutput.connection(with: .video),
            connection.isEnabled, connection.isActive
        else {
            set(error: .cameraUnavailable)
            print("Camera unavailable")
            return
        }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.photoQualityPrioritization = .balanced
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        self.sampleBuffer = imageBuffer
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            set(error: .cannotCaptureImage(error))
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            set(error: .cannotCaptureImage(nil))
            return
        }
        capturedImage = imageData
    }
}
