import UIKit

struct CameraPreviewImage<ImageType> {
    let image: ImageType
}

/**
 * Input from CameraAdapter, note: the bitmap should already be encoded in RGB value
 */
struct AnalyzerInput {
    let cameraPreviewImage: CameraPreviewImage<UIImage>
}

/**
 * Output interface of ML models
 */
protocol AnalyzerOutput {}

/**
 * Output of DocumentDetector
 */
struct DocumentDetectorOutput: AnalyzerOutput {
    let documents: [(UIImage, CGRect)]
    let resultScore: Float
}

/**
 * Output of FaceDetector
 */
struct FaceDetectorOutput: AnalyzerOutput {
    let faces: [(UIImage, CGRect)]
    let resultScore: Float
}

/**
 * Output of FaceLandmark
 */
struct FaceLandmarkOutput: AnalyzerOutput {
    let landmarks: [(UIImage, CGRect)]
    let resultScore: Float
}
