import Foundation
import UIKit

public final class WKAltTextDataController {
    
    public lazy var experimentStopDate: Date? = {
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 10
        dateComponents.day = 21
        return Calendar.current.date(from: dateComponents)
    }()
    
    public enum WKAltTextDataControllerError: Error {
        case notLoggedIn
        case invalidProject
        case invalidDeviceOrOS
        case invalidDate
        case unexpectedBucketValue
        case alreadyAssignedOtherExperiment
    }
    
    let experimentsDataController: WKExperimentsDataController
    let userDefaultsStore: WKKeyValueStore
    static let experimentPercentage = 50 //must be between 1 and 100
    
    // MARK: - Public
    
    public init?(experimentStore: WKKeyValueStore? = WKDataEnvironment.current.sharedCacheStore, userDefaultsStore: WKKeyValueStore? = WKDataEnvironment.current.userDefaultsStore) {
        
        guard let experimentStore,
        let userDefaultsStore else {
            return nil
        }
        
        self.experimentsDataController = WKExperimentsDataController(store: experimentStore)
        self.userDefaultsStore = userDefaultsStore
    }
    
    public func assignImageRecsExperiment(isLoggedIn: Bool, project: WKProject) throws {
        guard isLoggedIn else {
            throw WKAltTextDataControllerError.notLoggedIn
        }
        
        guard project.qualifiesForAltTextExperiments else {
            throw WKAltTextDataControllerError.invalidProject
        }
        
        guard isValidDeviceAndOS else {
            throw WKAltTextDataControllerError.invalidDeviceOrOS
        }
        
        guard isBeforeEndDate else {
            throw WKAltTextDataControllerError.invalidDate
        }
        
        if let articleEditorExperimentBucket = experimentsDataController.bucketForExperiment(.altTextArticleEditor) {
            
            switch articleEditorExperimentBucket {
            case .altTextArticleEditorTest:
                throw WKAltTextDataControllerError.alreadyAssignedOtherExperiment
            case .altTextArticleEditorControl:
                break
            default:
                throw WKAltTextDataControllerError.unexpectedBucketValue
            }
        }
        
        try experimentsDataController.determineBucketForExperiment(.altTextImageRecommendations, withPercentage: Self.experimentPercentage)
        
    }
    
    public func assignArticleEditorExperiment(isLoggedIn: Bool, project: WKProject) throws {
        guard isLoggedIn else {
            throw WKAltTextDataControllerError.notLoggedIn
        }
        
        guard project.qualifiesForAltTextExperiments else {
            throw WKAltTextDataControllerError.invalidProject
        }
        
        guard isValidDeviceAndOS else {
            throw WKAltTextDataControllerError.invalidDeviceOrOS
        }
        
        guard isBeforeEndDate else {
            throw WKAltTextDataControllerError.invalidDate
        }
        
        if let imageRecommendationsExperimentBucket = experimentsDataController.bucketForExperiment(.altTextImageRecommendations) {
            
            switch imageRecommendationsExperimentBucket {
            case .altTextImageRecommendationsTest:
                throw WKAltTextDataControllerError.alreadyAssignedOtherExperiment
            case .altTextImageRecommendationsControl:
                break
            default:
                throw WKAltTextDataControllerError.unexpectedBucketValue
            }
        }
        
        try experimentsDataController.determineBucketForExperiment(.altTextArticleEditor, withPercentage: Self.experimentPercentage)
    }
    
    public func markSawAltTextImageRecommendationsPrompt() {
        self.sawAltTextImageRecommendationsPrompt = true
    }
    
    public func shouldEnterAltTextImageRecommendationsFlow(isLoggedIn: Bool, project: WKProject) -> Bool {
        guard sawAltTextImageRecommendationsPrompt == false else {
            return false
        }
        
        guard isLoggedIn else {
            return false
        }
        
        guard project.qualifiesForAltTextExperiments else {
            return false
        }
        
        guard isValidDeviceAndOS else {
            return false
        }
        
        guard isBeforeEndDate else {
            return false
        }
        
        guard let imageRecommendationsExperimentBucket = experimentsDataController.bucketForExperiment(.altTextImageRecommendations) else {
            return false
        }
            
        switch imageRecommendationsExperimentBucket {
        case .altTextImageRecommendationsTest:
            return true
        default:
            return false
        }
    }
    
    public func markSawAltTextArticleEditorPrompt() {
        self.sawAltTextArticleEditorPrompt = true
    }
    
    public func shouldEnterAltTextArticleEditorFlow(isLoggedIn: Bool, project: WKProject) -> Bool {
        guard sawAltTextImageRecommendationsPrompt == false else {
            return false
        }
        
        guard isLoggedIn else {
            return false
        }
        
        guard project.qualifiesForAltTextExperiments else {
            return false
        }
        
        guard isValidDeviceAndOS else {
            return false
        }
        
        guard isBeforeEndDate else {
            return false
        }
        
        guard let articleEditorExperimentBucket = experimentsDataController.bucketForExperiment(.altTextArticleEditor) else {
            return false
        }
            
        switch articleEditorExperimentBucket {
        case .altTextArticleEditorTest:
            return true
        default:
            return false
        }
    }
    
    public func assignedGroupForLogging() -> String? {
        if let imageRecommendationsExperimentBucket = experimentsDataController.bucketForExperiment(.altTextImageRecommendations) {
            switch imageRecommendationsExperimentBucket {
            case .altTextImageRecommendationsTest:
                return "B"
            case .altTextImageRecommendationsControl:
                return "A"
            default:
                break
            }
        }
        
        if let articleEditorExperimentBucket = experimentsDataController.bucketForExperiment(.altTextArticleEditor) {
            switch articleEditorExperimentBucket {
            case .altTextArticleEditorTest:
                return "C"
            case .altTextArticleEditorControl:
                return "D"
            default:
                break
            }
        }
        
        return nil
    }
    
    // MARK: - Private
    
    private var isValidDeviceAndOS: Bool {
        if #available(iOS 16, *) {
            return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
        } else {
            return false
        }
    }
    
    private var isBeforeEndDate: Bool {
        
        guard let experimentStopDate else {
            return false
        }
        
        return experimentStopDate <= Date()
    }
    
    private var sawAltTextImageRecommendationsPrompt: Bool {
        get {
            return (try? userDefaultsStore.load(key: WKUserDefaultsKey.sawAltTextImageRecommendationsPrompt.rawValue)) ?? false
        } set {
            try? userDefaultsStore.save(key: WKUserDefaultsKey.sawAltTextImageRecommendationsPrompt.rawValue, value: newValue)
        }
    }
    
    private var sawAltTextArticleEditorPrompt: Bool {
        get {
            return (try? userDefaultsStore.load(key: WKUserDefaultsKey.sawAltTextArticleEditorPrompt.rawValue)) ?? false
        } set {
            try? userDefaultsStore.save(key: WKUserDefaultsKey.sawAltTextArticleEditorPrompt.rawValue, value: newValue)
        }
    }
    
}

private extension WKProject {
    var qualifiesForAltTextExperiments: Bool {
        switch self {
        case .wikipedia(let language):
            switch language.languageCode {
            case "es", "fr", "pt", "zh":
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
