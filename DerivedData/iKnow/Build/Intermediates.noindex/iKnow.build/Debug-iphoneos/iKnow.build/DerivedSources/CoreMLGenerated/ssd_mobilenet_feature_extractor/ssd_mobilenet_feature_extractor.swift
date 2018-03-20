//
// ssd_mobilenet_feature_extractor.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class ssd_mobilenet_feature_extractorInput : MLFeatureProvider {

    /// Preprocessor__sub__0 as color (kCVPixelFormatType_32BGRA) image buffer, 300 pixels wide by 300 pixels high
    var Preprocessor__sub__0: CVPixelBuffer
    
    var featureNames: Set<String> {
        get {
            return ["Preprocessor__sub__0"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "Preprocessor__sub__0") {
            return MLFeatureValue(pixelBuffer: Preprocessor__sub__0)
        }
        return nil
    }
    
    init(Preprocessor__sub__0: CVPixelBuffer) {
        self.Preprocessor__sub__0 = Preprocessor__sub__0
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class ssd_mobilenet_feature_extractorOutput : MLFeatureProvider {

    /// concat_1__0 as multidimensional array of doubles
    let concat_1__0: MLMultiArray

    /// concat__0 as multidimensional array of doubles
    let concat__0: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["concat_1__0", "concat__0"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "concat_1__0") {
            return MLFeatureValue(multiArray: concat_1__0)
        }
        if (featureName == "concat__0") {
            return MLFeatureValue(multiArray: concat__0)
        }
        return nil
    }
    
    init(concat_1__0: MLMultiArray, concat__0: MLMultiArray) {
        self.concat_1__0 = concat_1__0
        self.concat__0 = concat__0
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class ssd_mobilenet_feature_extractor {
    var model: MLModel

    /**
        Construct a model with explicit path to mlmodel file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    convenience init() {
        let bundle = Bundle(for: ssd_mobilenet_feature_extractor.self)
        let assetPath = bundle.url(forResource: "ssd_mobilenet_feature_extractor", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as ssd_mobilenet_feature_extractorInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as ssd_mobilenet_feature_extractorOutput
    */
    func prediction(input: ssd_mobilenet_feature_extractorInput) throws -> ssd_mobilenet_feature_extractorOutput {
        let outFeatures = try model.prediction(from: input)
        let result = ssd_mobilenet_feature_extractorOutput(concat_1__0: outFeatures.featureValue(for: "concat_1__0")!.multiArrayValue!, concat__0: outFeatures.featureValue(for: "concat__0")!.multiArrayValue!)
        return result
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - Preprocessor__sub__0 as color (kCVPixelFormatType_32BGRA) image buffer, 300 pixels wide by 300 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as ssd_mobilenet_feature_extractorOutput
    */
    func prediction(Preprocessor__sub__0: CVPixelBuffer) throws -> ssd_mobilenet_feature_extractorOutput {
        let input_ = ssd_mobilenet_feature_extractorInput(Preprocessor__sub__0: Preprocessor__sub__0)
        return try self.prediction(input: input_)
    }
}
