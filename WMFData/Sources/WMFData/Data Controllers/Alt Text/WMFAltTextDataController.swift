import Foundation
import UIKit

public final class WMFAltTextDataController {
    
    struct OnboardingStatus: Codable {
        var hasPresentedOnboardingModal: Bool
        var hasPresentedOnboardingTooltips: Bool

        static var `default`: OnboardingStatus {
            return OnboardingStatus(hasPresentedOnboardingModal: false, hasPresentedOnboardingTooltips: false)
        }
    }
    
    public static let shared = WMFAltTextDataController()
    
    public lazy var experimentStopDate: Date? = {
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 11
        dateComponents.day = 5
        return Calendar.current.date(from: dateComponents)
    }()
    
    public enum WMFAltTextDataControllerError: Error {
        case notPermanent
        case invalidProject
        case invalidDeviceOrOS
        case invalidDate
        case unexpectedBucketValue
        case alreadyAssignedThisExperiment
        case alreadyAssignedOtherExperiment
    }
    
    private let experimentsDataController: WMFExperimentsDataController
    private let developerSettingsDataController: WMFDeveloperSettingsDataController
    private let userDefaultsStore: WMFKeyValueStore
    private var experimentPercentage: Int = 100

    // MARK: - Public
    
    public init?(experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        
        guard let experimentStore,
        let userDefaultsStore else {
            return nil
        }
        
        self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        self.developerSettingsDataController = WMFDeveloperSettingsDataController.shared
        self.userDefaultsStore = userDefaultsStore
    }
    
    public func assignImageRecsExperiment(isPermanent: Bool, project: WMFProject) throws {
        
        guard isPermanent else {
            throw WMFAltTextDataControllerError.notPermanent
        }
        
        guard project.qualifiesForAltTextExperiments(developerSettingsDataController: developerSettingsDataController) else {
            throw WMFAltTextDataControllerError.invalidProject
        }
        
        guard isValidDeviceAndOS else {
            throw WMFAltTextDataControllerError.invalidDeviceOrOS
        }
        
        guard isBeforeEndDate else {
            throw WMFAltTextDataControllerError.invalidDate
        }
        
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            if experimentsDataController.bucketForExperiment(.altTextImageRecommendations) != nil {
                throw WMFAltTextDataControllerError.alreadyAssignedThisExperiment
            }
        }
        
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            if let articleEditorExperimentBucket = experimentsDataController.bucketForExperiment(.altTextArticleEditor) {
                
                switch articleEditorExperimentBucket {
                case .altTextArticleEditorTest:
                    throw WMFAltTextDataControllerError.alreadyAssignedOtherExperiment
                case .altTextArticleEditorControl:
                    break
                default:
                    throw WMFAltTextDataControllerError.unexpectedBucketValue
                }
            }
        }
        
        try experimentsDataController.determineBucketForExperiment(.altTextImageRecommendations, withPercentage: experimentPercentage)
        
    }
    
    public func assignArticleEditorExperiment(isPermanent: Bool, project: WMFProject) throws {
        
        guard isPermanent else {
            throw WMFAltTextDataControllerError.notPermanent
        }
        
        guard project.qualifiesForAltTextExperiments(developerSettingsDataController: developerSettingsDataController) else {
            throw WMFAltTextDataControllerError.invalidProject
        }
        
        guard isValidDeviceAndOS else {
            throw WMFAltTextDataControllerError.invalidDeviceOrOS
        }
        
        guard isBeforeEndDate else {
            throw WMFAltTextDataControllerError.invalidDate
        }
        
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            if experimentsDataController.bucketForExperiment(.altTextArticleEditor) != nil {
                throw WMFAltTextDataControllerError.alreadyAssignedThisExperiment
            }
        }
        
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            if let imageRecommendationsExperimentBucket = experimentsDataController.bucketForExperiment(.altTextImageRecommendations) {
                
                switch imageRecommendationsExperimentBucket {
                case .altTextImageRecommendationsTest:
                    throw WMFAltTextDataControllerError.alreadyAssignedOtherExperiment
                case .altTextImageRecommendationsControl:
                    break
                default:
                    throw WMFAltTextDataControllerError.unexpectedBucketValue
                }
            }
        }
        
        try experimentsDataController.determineBucketForExperiment(.altTextArticleEditor, withPercentage: experimentPercentage)
    }
    
    public func markSawAltTextImageRecommendationsPrompt() {
        
        self.sawAltTextImageRecommendationsPrompt = true
    }
    
    public func shouldEnterAltTextImageRecommendationsFlow(isPermanent: Bool, project: WMFProject) -> Bool {
        
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            guard sawAltTextImageRecommendationsPrompt == false && sawAltTextArticleEditorPrompt == false else {
                return false
            }
        }
        
        guard isPermanent else {
            return false
        }
        
        guard project.qualifiesForAltTextExperiments(developerSettingsDataController: developerSettingsDataController) else {
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
    
    public func shouldFetchFullArticleWikitextFromArticleEditor(isPermanent: Bool, project: WMFProject) -> Bool {

        // haven't already seen the prompt elsewhere
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            guard sawAltTextImageRecommendationsPrompt == false && sawAltTextArticleEditorPrompt == false else {
                return false
            }
        }
        
        // is permanent
        guard isPermanent else {
            return false
        }
        
        // is looking at the target experiment wikis
        guard project.qualifiesForAltTextExperiments(developerSettingsDataController: developerSettingsDataController) else {
            return false
        }
        
        // iPhone, iOS 16+
        guard isValidDeviceAndOS else {
            return false
        }
        
        // Before Oct 10
        guard isBeforeEndDate else {
            return false
        }
        
        // Hasn't already been assigned the alt text editor experiment
        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            guard experimentsDataController.bucketForExperiment(.altTextArticleEditor) == nil else {
                return false
            }
        }
        
        return true
    }
    
    public func shouldEnterAltTextArticleEditorFlow(isPermanent: Bool, project: WMFProject) -> Bool {

        if !developerSettingsDataController.alwaysShowAltTextEntryPoint {
            guard sawAltTextImageRecommendationsPrompt == false && sawAltTextArticleEditorPrompt == false else {
                return false
            }
        }
        
        guard isPermanent else {
            return false
        }
        
        guard project.qualifiesForAltTextExperiments(developerSettingsDataController: developerSettingsDataController) else {
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
    
    public func assignedAltTextImageRecommendationsGroupForLogging() -> String? {

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
        
        return nil
    }
    
    public func assignedAltTextArticleEditorGroupForLogging() -> String? {
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
    
    // MARK: - Onboarding
    
    private var onboardingStatus: OnboardingStatus {
        return (try? userDefaultsStore.load(key: WMFUserDefaultsKey.altTextExperimentOnboarding.rawValue)) ?? OnboardingStatus.default
    }

    public var hasPresentedOnboardingModal: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingModal
        } set {
            var currentOnboardingStatus = onboardingStatus
            currentOnboardingStatus.hasPresentedOnboardingModal = newValue
            try? userDefaultsStore.save(key: WMFUserDefaultsKey.altTextExperimentOnboarding.rawValue, value: currentOnboardingStatus)
        }
    }
    
    public var hasPresentedOnboardingTooltips: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingTooltips
        } set {
            var currentOnboardingStatus = onboardingStatus
            currentOnboardingStatus.hasPresentedOnboardingTooltips = newValue
            try? userDefaultsStore.save(key: WMFUserDefaultsKey.altTextExperimentOnboarding.rawValue, value: currentOnboardingStatus)
        }
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
        
        return experimentStopDate >= Date()
    }
    
    private var sawAltTextImageRecommendationsPrompt: Bool {
        get {
            return (try? userDefaultsStore.load(key: WMFUserDefaultsKey.sawAltTextImageRecommendationsPrompt.rawValue)) ?? false
        } set {
            try? userDefaultsStore.save(key: WMFUserDefaultsKey.sawAltTextImageRecommendationsPrompt.rawValue, value: newValue)
        }
    }
    
    private var sawAltTextArticleEditorPrompt: Bool {
        get {
            return (try? userDefaultsStore.load(key: WMFUserDefaultsKey.sawAltTextArticleEditorPrompt.rawValue)) ?? false
        } set {
            try? userDefaultsStore.save(key: WMFUserDefaultsKey.sawAltTextArticleEditorPrompt.rawValue, value: newValue)
        }
    }
    
}

private extension WMFProject {
    func qualifiesForAltTextExperiments(developerSettingsDataController: WMFDeveloperSettingsDataController) -> Bool {
        switch self {
        case .wikipedia(let language):
            switch language.languageCode {
            case "es", "fr", "pt", "zh", "test":
                return true
            case "en":
                return developerSettingsDataController.enableAltTextExperimentForEN
            default:
                return false
            }
        default:
            return false
        }
    }
}
