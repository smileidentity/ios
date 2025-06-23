import AVFoundation

extension AVCaptureDevice {
    // Returns the total number of available camera devices.
    static var numberOfCameras: Int {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInUltraWideCamera,
                .builtInTrueDepthCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices.count
    }
}
