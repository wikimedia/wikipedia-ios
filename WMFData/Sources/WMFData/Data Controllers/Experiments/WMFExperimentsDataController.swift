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
        let bucketValueTest2: BucketValue?
    }
    
    public enum Experiment {
        case activityTab
        case moreDynamicTabs

        var config: ExperimentConfig {
            switch self {
            case .activityTab:
                return WMFExperimentsDataController.activityTabConfig
            case .moreDynamicTabs:
                return WMFExperimentsDataController.moreDynamicTabsConfig
            }
        }
    }
    
    public enum PercentageFileName: String {
        case activityTabPercent
        case moreDynamicTabsPercent
    }
    
    enum BucketFileName: String {
        case activityTabBucket
        case moreDynamicTabsBucket
    }
    
    public enum BucketValue: String {
        case activityTabGroupAControl = "ActivityTab_GroupA_Control"
        case activityTabGroupBEdit = "ActivityTab_GroupB_Edit"
        case activityTabGroupCSuggestedEdit = "ActivityTab_GroupC_SuggestedEdit"
        case moreDynamicTabsControl = "MoreDynamicTabs_Control"
        case moreDynamicTabsBecauseYouRead = "MoreDynamicTabs_BecauseYouRead"
        case moreDynamicTabsDidYouKnow = "MoreDynamicTabs_DidYouKnow"
    }
    
    // MARK: Properties
    
    private let cacheDirectoryName = WMFSharedCacheDirectoryNames.experiments.rawValue

    private static let activityTabConfig = ExperimentConfig(experiment: .activityTab, percentageFileName: .activityTabPercent, bucketFileName: .activityTabBucket, bucketValueControl: .activityTabGroupAControl, bucketValueTest: .activityTabGroupBEdit, bucketValueTest2: .activityTabGroupCSuggestedEdit)

    private static let moreDynamicTabsConfig = ExperimentConfig(experiment: .moreDynamicTabs, percentageFileName: .moreDynamicTabsPercent, bucketFileName: .moreDynamicTabsBucket, bucketValueControl: .moreDynamicTabsControl, bucketValueTest: .moreDynamicTabsBecauseYouRead, bucketValueTest2: .moreDynamicTabsDidYouKnow)

    private let store: WMFKeyValueStore
    
    // MARK: Lifecycle
    
    public init(store: WMFKeyValueStore) {
        self.store = store
    }
    
    // MARK: Public
    
    // this will only generate a new bucket as needed (i.e. if the percentage is different than the last time bucket was generated)
    // forceValue: optional forcing of bucket assignment (i.e. developer settings menu assignments)
    @discardableResult
    func determineBucketForExperiment(_ experiment: Experiment, withPercentage percentage: Int, forceValue: BucketValue? = nil) throws -> BucketValue {
        
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
        let bucket: BucketValue
        
        if let forceValue = forceValue {
            bucket = forceValue
        } else {
            switch experiment {
            case .moreDynamicTabs:
                if randomInt <= percentage {
                    bucket = .moreDynamicTabsControl
                } else if randomInt > percentage && randomInt <= percentage*2 {
                    bucket = .moreDynamicTabsBecauseYouRead
                } else {
                    bucket = .moreDynamicTabsDidYouKnow
                }
            case .activityTab:
                if randomInt <= percentage {
                    bucket = .activityTabGroupAControl
                } else if randomInt > percentage && randomInt <= percentage*2 {
                    bucket = .activityTabGroupBEdit
                } else {
                    bucket = .activityTabGroupCSuggestedEdit
                }
            }
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
