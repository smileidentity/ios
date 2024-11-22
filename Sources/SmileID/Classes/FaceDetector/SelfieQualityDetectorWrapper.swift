import Foundation
import CoreML

class SelfieQualityDetectorWrapper: SelfieQualityDetectorProtocol {
    private let selfieQualityModel: SelfieQualityDetector?
    
    init() {
        let modelConfiguration = MLModelConfiguration()
        selfieQualityModel = try? SelfieQualityDetector(configuration: modelConfiguration)
    }
    
    func predict(imageBuffer: CVPixelBuffer) throws -> SelfieQualityData {
        guard let selfieQualityModel else {
            throw FaceDetectorError.unableToLoadSelfieModel
        }
        let input = SelfieQualityDetectorInput(conv2d_193_input: imageBuffer)

        let prediction = try selfieQualityModel.prediction(input: input)
        let output = prediction.Identity

        guard output.shape.count == 2,
            output.shape[0] == 1,
            output.shape[1] == 2
        else {
            throw FaceDetectorError.invalidSelfieModelOutput
        }

        let passScore = output[0].floatValue
        let failScore = output[1].floatValue

        let selfieQualityData = SelfieQualityData(
            failed: failScore,
            passed: passScore
        )
        return selfieQualityData
    }
}
