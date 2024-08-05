import Foundation

final class WMFExperimentsDataController {
    
    // MARK: - Nested Types
    
    enum ExperimentError: Error {
        case invalidPercentage
    }
    
    struct ExperimentConfig {
        let experiment: Experiment
        let percentageFileName: PercentageFileName
        let bucketFileName: BucketFileName
        let bucketValueControl: BucketValue
        let bucketValueTest: BucketValue
    }
    
    public enum Experiment {
        case articleAsLivingDoc
        case altTextImageRecommendations
        case altTextArticleEditor
        
        var config: ExperimentConfig {
            switch self {
            case .articleAsLivingDoc:
                return WMFExperimentsDataController.articleAsLivingDocConfig
            case .altTextImageRecommendations:
                return WMFExperimentsDataController.altTextImageRecommendationsConfig
            case .altTextArticleEditor:
                return WMFExperimentsDataController.altTextArticleEditorConfig
            }
        }
    }
    
    public enum PercentageFileName: String {
        case articleAsLivingDocPercent
        case altTextImageRecommendationsPercent
        case altTextArticleEditorPercent
    }
    
    enum BucketFileName: String {
        case articleAsLivingDocBucket
        case altTextImageRecommendationsBucket
        case altTextArticleEditorBucket
    }
    
    public enum BucketValue: String {
        case articleAsLivingDocTest = "LivingDoc_Test"
        case articleAsLivingDocControl = "LivingDoc_Control"
        case altTextImageRecommendationsTest = "AltTextImageRecommendations_Test"
        case altTextImageRecommendationsControl = "AltTextImageRecommendations_Control"
        case altTextArticleEditorTest = "AltTextArticleEditor_Test"
        case altTextArticleEditorControl = "AltTextArticleEditor_Control"
    }
    
    // MARK: Properties
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.experiments.rawValue
    
    private static let articleAsLivingDocConfig = ExperimentConfig(experiment: .articleAsLivingDoc, percentageFileName: .articleAsLivingDocPercent, bucketFileName: .articleAsLivingDocBucket, bucketValueControl: .articleAsLivingDocControl, bucketValueTest: .articleAsLivingDocTest)
    
    private static let altTextImageRecommendationsConfig = ExperimentConfig(experiment: .altTextImageRecommendations, percentageFileName: .altTextImageRecommendationsPercent, bucketFileName: .altTextImageRecommendationsBucket, bucketValueControl: .altTextImageRecommendationsControl, bucketValueTest: .altTextImageRecommendationsTest)
    
    private static let altTextArticleEditorConfig = ExperimentConfig(experiment: .altTextArticleEditor, percentageFileName: .altTextArticleEditorPercent, bucketFileName: .altTextArticleEditorBucket, bucketValueControl: .altTextArticleEditorControl, bucketValueTest: .altTextArticleEditorTest)
    
    private let store: WMFKeyValueStore
    
    // MARK: Lifecycle
    
    public init(store: WMFKeyValueStore) {
        self.store = store
    }
    
    // MARK: Public
    
    // this will only generate a new bucket as needed (i.e. if the percentage is different than the last time bucket was generated)
    @discardableResult
    func determineBucketForExperiment(_ experiment: Experiment, withPercentage percentage: Int) throws -> BucketValue {
        
        guard percentage >= 0 && percentage <= 100 else {
            throw ExperimentError.invalidPercentage
        }
        
        // if we have previously generated a bucket with the same percentage, return that value
        let maybeOldPercentage = percentageForExperiment(experiment)
        let maybeOldBucket = bucketForExperiment(experiment)
        
        if let oldPercentage = maybeOldPercentage,
           let oldBucket = maybeOldBucket,
           oldPercentage == percentage {
            return oldBucket
        }
        
        // otherwise generate new bucket
        let randomInt = Int.random(in: 1...100)
        let isInTest = randomInt <= percentage
        let bucket: BucketValue
        
        switch experiment {
        case .articleAsLivingDoc:
            bucket = isInTest ? .articleAsLivingDocTest : .articleAsLivingDocControl
        case .altTextImageRecommendations:
            bucket = isInTest ? .altTextImageRecommendationsTest : .altTextImageRecommendationsControl
        case .altTextArticleEditor:
            bucket = isInTest ? .altTextArticleEditorTest : .altTextArticleEditorControl
        }
        
        try setBucket(bucket, forExperiment: experiment)
        try setPercentage(percentage, forExperiment: experiment)
        
        return bucket
    }
    
    func bucketForExperiment(_ experiment: Experiment) -> BucketValue? {
        
        let key = experiment.config.bucketFileName.rawValue
        guard let rawValue: String = try? store.load(key: cacheDirectoryName, key) else {
            return nil
        }
        
        return BucketValue(rawValue: rawValue)
    }
    
    // MARK: Private
    
    private func percentageForExperiment(_ experiment: Experiment) -> Int? {
        
        let key = experiment.config.percentageFileName.rawValue
        let percentage: Int? = try? store.load(key: cacheDirectoryName, key)
        return percentage
    }
    
    private func setPercentage(_ percentage: Int, forExperiment experiment: Experiment) throws {
        
        guard percentage >= 0 && percentage <= 100 else {
            throw ExperimentError.invalidPercentage
        }
        
        let key = experiment.config.percentageFileName.rawValue
        try store.save(key: cacheDirectoryName, key, value: percentage)
    }
    
    private func setBucket(_ bucket: BucketValue, forExperiment experiment: Experiment) throws {
        
        let key = experiment.config.bucketFileName.rawValue
        try store.save(key: cacheDirectoryName, key, value: bucket.rawValue)
    }
}
