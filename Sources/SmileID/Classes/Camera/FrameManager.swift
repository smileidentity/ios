//import AVFoundation
//
//class FrameManager: NSObject, ObservableObject {
//     @Published var sampleBuffer: CVPixelBuffer?
//     let videoOutputQueue = DispatchQueue(label: "com.smileid.videooutput",
//                                          qos: .userInitiated,
//                                          attributes: [],
//                                          autoreleaseFrequency: .workItem)
//
//    private let cameraManager: CameraManager
//
//    init(cameraManager: CameraManager) {
//        self.cameraManager = cameraManager
//        super.init()
//        self.cameraManager.set(self, queue: videoOutputQueue)
//    }
//}
//
//extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//  func captureOutput(_ output: AVCaptureOutput,
//                     didOutput sampleBuffer: CMSampleBuffer,
//                     from connection: AVCaptureConnection) {
//    if let buffer = sampleBuffer.imageBuffer {
//        self.sampleBuffer = buffer
//    }
//  }
//}
