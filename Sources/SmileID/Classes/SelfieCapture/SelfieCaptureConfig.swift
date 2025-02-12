import Foundation

struct SelfieCaptureConfig {
    let intraImageMinDelay: TimeInterval
    let noFaceResetDelay: TimeInterval
    let faceCaptureQualityThreshold: Float
    let minFaceCenteredThreshold: Double
    let maxFaceCenteredThreshold: Double
    let minFaceAreaThreshold: Double
    let maxFaceAreaThreshold: Double
    let faceRotationThreshold: Double
    let faceRollThreshold: Double
    let numLivenessImages: Int
    let numTotalSteps: Int
    let livenessImageSize: Int
    let selfieImageSize: Int

    init(
        intraImageMinDelay: TimeInterval,
        noFaceResetDelay: TimeInterval,
        faceCaptureQualityThreshold: Float,
        minFaceCenteredThreshold: Double,
        maxFaceCenteredThreshold: Double,
        minFaceAreaThreshold: Double,
        maxFaceAreaThreshold: Double,
        faceRotationThreshold: Double,
        faceRollThreshold: Double,
        numLivenessImages: Int,
        numTotalSteps: Int,
        livenessImageSize: Int,
        selfieImageSize: Int
    ) {
        self.intraImageMinDelay = intraImageMinDelay
        self.noFaceResetDelay = noFaceResetDelay
        self.faceCaptureQualityThreshold = faceCaptureQualityThreshold
        self.minFaceCenteredThreshold = minFaceCenteredThreshold
        self.maxFaceCenteredThreshold = maxFaceCenteredThreshold
        self.minFaceAreaThreshold = minFaceAreaThreshold
        self.maxFaceAreaThreshold = maxFaceAreaThreshold
        self.faceRotationThreshold = faceRotationThreshold
        self.faceRollThreshold = faceRollThreshold
        self.numLivenessImages = numLivenessImages
        self.numTotalSteps = numTotalSteps
        self.livenessImageSize = livenessImageSize
        self.selfieImageSize = selfieImageSize
    }

    static var defaultConfiguration = SelfieCaptureConfig(
        intraImageMinDelay: 0.35,
        noFaceResetDelay: 3,
        faceCaptureQualityThreshold: 0.25,
        minFaceCenteredThreshold: 0.1,
        maxFaceCenteredThreshold: 0.9,
        minFaceAreaThreshold: 0.125,
        maxFaceAreaThreshold: 0.25,
        faceRotationThreshold: 0.03,
        faceRollThreshold: 0.025,  // roll has a smaller range than yaw
        numLivenessImages: 7,
        numTotalSteps: 8,  // numLivenessImages + 1 selfie image
        livenessImageSize: 320,
        selfieImageSize: 640
    )
}
