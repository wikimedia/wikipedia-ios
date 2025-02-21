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
        case articleSearchBar
        
        var config: ExperimentConfig {
            switch self {
            case .articleSearchBar:
                return WMFExperimentsDataController.articleSearchBarConfig
            }
        }
    }
    
    public enum PercentageFileName: String {
        case articleSearchBarPercent
    }
    
    enum BucketFileName: String {
        case articleSearchBarBucket
    }
    
    public enum BucketValue: String {
        case articleSearchBarTest = "ArticleSearchBar_Test"
        case articleSearchBarControl = "ArticleSearchBar_Control"
    }
    
    // MARK: Properties
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.experiments.rawValue
    
    private static let articleSearchBarConfig = ExperimentConfig(experiment: .articleSearchBar, percentageFileName: .articleSearchBarPercent, bucketFileName: .articleSearchBarBucket, bucketValueControl: .articleSearchBarControl, bucketValueTest: .articleSearchBarTest)
    
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
        case .articleSearchBar:
            bucket = isInTest ? .articleSearchBarTest : .articleSearchBarControl
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
    
    func resetExperiment(_ experiment: Experiment) throws {
        let bucketKey = experiment.config.bucketFileName.rawValue
        let percentKey = experiment.config.percentageFileName.rawValue
        try store.remove(key: cacheDirectoryName, bucketKey)
        try store.remove(key: cacheDirectoryName, percentKey)
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
