//
// SelfieQualityDetector.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SelfieQualityDetectorInput : MLFeatureProvider {

    /// conv2d_193_input as color (kCVPixelFormatType_32BGRA) image buffer, 120 pixels wide by 120 pixels high
    var conv2d_193_input: CVPixelBuffer

    var featureNames: Set<String> {
        get {
            return ["conv2d_193_input"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "conv2d_193_input") {
            return MLFeatureValue(pixelBuffer: conv2d_193_input)
        }
        return nil
    }
    
    init(conv2d_193_input: CVPixelBuffer) {
        self.conv2d_193_input = conv2d_193_input
    }

    convenience init(conv2d_193_inputWith conv2d_193_input: CGImage) throws {
        self.init(conv2d_193_input: try MLFeatureValue(cgImage: conv2d_193_input, pixelsWide: 120, pixelsHigh: 120, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }

    convenience init(conv2d_193_inputAt conv2d_193_input: URL) throws {
        self.init(conv2d_193_input: try MLFeatureValue(imageAt: conv2d_193_input, pixelsWide: 120, pixelsHigh: 120, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!)
    }

    func setConv2d_193_input(with conv2d_193_input: CGImage) throws  {
        self.conv2d_193_input = try MLFeatureValue(cgImage: conv2d_193_input, pixelsWide: 120, pixelsHigh: 120, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

    func setConv2d_193_input(with conv2d_193_input: URL) throws  {
        self.conv2d_193_input = try MLFeatureValue(imageAt: conv2d_193_input, pixelsWide: 120, pixelsHigh: 120, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil).imageBufferValue!
    }

}


/// Model Prediction Output Type
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SelfieQualityDetectorOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// Identity as multidimensional array of floats
    var Identity: MLMultiArray {
        return self.provider.featureValue(for: "Identity")!.multiArrayValue!
    }

    /// Identity as multidimensional array of floats
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    var IdentityShapedArray: MLShapedArray<Float> {
        return MLShapedArray<Float>(self.Identity)
    }

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(Identity: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["Identity" : MLFeatureValue(multiArray: Identity)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SelfieQualityDetector {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "SelfieQualityDetector", withExtension:"mlmodelc")!
    }

    /**
        Construct SelfieQualityDetector instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of SelfieQualityDetector.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `SelfieQualityDetector.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct SelfieQualityDetector instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct SelfieQualityDetector instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct SelfieQualityDetector instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<SelfieQualityDetector, Error>) -> Void) {
        return self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct SelfieQualityDetector instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> SelfieQualityDetector {
        return try await self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct SelfieQualityDetector instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<SelfieQualityDetector, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(SelfieQualityDetector(model: model)))
            }
        }
    }

    /**
        Construct SelfieQualityDetector instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> SelfieQualityDetector {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return SelfieQualityDetector(model: model)
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as SelfieQualityDetectorInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as SelfieQualityDetectorOutput
    */
    func prediction(input: SelfieQualityDetectorInput) throws -> SelfieQualityDetectorOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as SelfieQualityDetectorInput
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as SelfieQualityDetectorOutput
    */
    func prediction(input: SelfieQualityDetectorInput, options: MLPredictionOptions) throws -> SelfieQualityDetectorOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return SelfieQualityDetectorOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        - parameters:
           - input: the input to the prediction as SelfieQualityDetectorInput
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as SelfieQualityDetectorOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    func prediction(input: SelfieQualityDetectorInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> SelfieQualityDetectorOutput {
        let outFeatures = try await model.prediction(from: input, options:options)
        return SelfieQualityDetectorOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - conv2d_193_input as color (kCVPixelFormatType_32BGRA) image buffer, 120 pixels wide by 120 pixels high

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as SelfieQualityDetectorOutput
    */
    func prediction(conv2d_193_input: CVPixelBuffer) throws -> SelfieQualityDetectorOutput {
        let input_ = SelfieQualityDetectorInput(conv2d_193_input: conv2d_193_input)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        - parameters:
           - inputs: the inputs to the prediction as [SelfieQualityDetectorInput]
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [SelfieQualityDetectorOutput]
    */
    func predictions(inputs: [SelfieQualityDetectorInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [SelfieQualityDetectorOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [SelfieQualityDetectorOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  SelfieQualityDetectorOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
