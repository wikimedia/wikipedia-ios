

import Foundation

@objc public protocol ABTestsPersisting: class {
    func libraryValue(for key: String) -> NSCoding?
    func setLibraryValue(_ value: NSCoding?, for key: String)
}

@objc(WMFABTestsController)
public class ABTestsController: NSObject {
    
    enum ABTestsError: Error {
        case invalidPercentage
    }
    
    struct ExperimentConfig {
        let experiment: Experiment
        let percentageKey: PercentageKey
        let bucketKey: BucketKey
        let bucketValueControl: BucketValue
        let bucketValueTest: BucketValue
    }
    
    public enum Experiment {
        case articleAsLivingDoc
        
        var config: ExperimentConfig {
            switch self {
            case .articleAsLivingDoc:
                return ABTestsController.articleAsLivingDocConfig
            }
        }
    }
    
    public enum PercentageKey: String {
        case articleAsLivingDocPercentKey
    }
    
    enum BucketKey: String {
        case articleAsLivingDocBucketKey
    }
    
    public enum BucketValue: String {
        case articleAsLivingDocTest = "LivingDoc_Test"
        case articleAsLivingDocControl = "LivingDoc_Control"
    }
    
    private static let articleAsLivingDocConfig = ExperimentConfig(experiment: .articleAsLivingDoc, percentageKey: .articleAsLivingDocPercentKey, bucketKey: .articleAsLivingDocBucketKey, bucketValueControl: .articleAsLivingDocControl, bucketValueTest: .articleAsLivingDocTest)
    
    private let persistanceService: ABTestsPersisting
    
    @objc public init(persistanceService: ABTestsPersisting) {
        self.persistanceService = persistanceService
        super.init()
    }
    
    //this will only generate a new bucket as needed (i.e. if the percentage is different than the last time bucket was generated)
    @discardableResult
    func determineBucketForExperiment(_ experiment: Experiment, withPercentage percentage: NSNumber) throws -> BucketValue {
        
        guard percentage.intValue >= 0 && percentage.intValue <= 100 else {
            throw ABTestsError.invalidPercentage
        }
        
        //if we have previously generated a bucket with the same percentage, return that value
        let maybeOldPercentage = percentageForExperiment(experiment)
        let maybeOldBucket = bucketForExperiment(experiment)
        
        if let oldPercentage = maybeOldPercentage,
           let oldBucket = maybeOldBucket,
           oldPercentage == percentage {
            return oldBucket
        }
        
        //otherwise generate new bucket
        let randomInt = Int.random(in: 1...100)
        let isInTest = randomInt <= percentage.intValue
        let bucket: BucketValue
        
        switch experiment {
        case .articleAsLivingDoc:
            bucket = isInTest ? .articleAsLivingDocTest : .articleAsLivingDocControl
        }
        
        setBucket(bucket, forExperiment: experiment)
        try setPercentage(percentage, forExperiment: experiment)
        
        return bucket
    }
    
    //MARK: Persistence setters/getters
    
    func percentageForExperiment(_ experiment: Experiment) -> NSNumber? {
        
        let key = experiment.config.percentageKey.rawValue
        return persistanceService.libraryValue(for: key) as? NSNumber
    }
    
    func setPercentage(_ percentage: NSNumber, forExperiment experiment: Experiment) throws {
        
        guard percentage.intValue >= 0 && percentage.intValue <= 100 else {
            throw ABTestsError.invalidPercentage
        }
        
        let key = experiment.config.percentageKey.rawValue
        persistanceService.setLibraryValue(percentage, for: key)
    }
    
    public func bucketForExperiment(_ experiment: Experiment) -> BucketValue? {
        
        let key = experiment.config.bucketKey.rawValue
        guard let rawValue = persistanceService.libraryValue(for: key) as? String else {
            return nil
        }
        
        return BucketValue(rawValue: rawValue)
    }
    
    func setBucket(_ bucket: BucketValue, forExperiment experiment: Experiment) {
        
        let key = experiment.config.bucketKey.rawValue
        persistanceService.setLibraryValue((bucket.rawValue as NSString), for: key)
    }
}
