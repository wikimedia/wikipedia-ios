import Foundation

public final class WMFNavigationExperimentsDataController {
    
    public enum CustomError: Error {
        case invalidProject
        case invalidDate
        case alreadyAssignedBucket
        case missingAssignment
        case unexpectedAssignment
    }
    
    public enum ArticleSearchBarExperimentAssignment {
        case control
        case test
    }
    
    public static let shared = WMFNavigationExperimentsDataController()
    private let experimentsDataController: WMFExperimentsDataController
    private let articleSearchBarExperimentPercentage: Int = 50
    
    private init?(experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        guard let experimentStore else {
            return nil
        }
        self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
    }
    
    public func assignArticleSearchBarExperiment(project: WMFProject) throws {
        
        guard project.qualifiesForNavigationV2Experiment() else {
            throw CustomError.invalidProject
        }
        
        guard isBeforeEndDate else {
            throw CustomError.invalidDate
        }
        
        if experimentsDataController.bucketForExperiment(.articleSearchBar) != nil {
            throw CustomError.alreadyAssignedBucket
        }
        
        try experimentsDataController.determineBucketForExperiment(.articleSearchBar, withPercentage: articleSearchBarExperimentPercentage)
    }
    
    public func articleSearchBarExperimentAssignment() throws -> ArticleSearchBarExperimentAssignment {
        guard let bucketValue = experimentsDataController.bucketForExperiment(.articleSearchBar) else {
            throw CustomError.missingAssignment
        }
        
        switch bucketValue {
        case .articleSearchBarTest:
            return ArticleSearchBarExperimentAssignment.test
        case .articleSearchBarControl:
            return ArticleSearchBarExperimentAssignment.control
        default:
            throw CustomError.unexpectedAssignment
        }
    }
    
    private var experimentStopDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 31
        dateComponents.day = 5
        return Calendar.current.date(from: dateComponents)
    }
    
    private var isBeforeEndDate: Bool {
        
        guard let experimentStopDate else {
            return false
        }
        
        return experimentStopDate >= Date()
    }
}

private extension WMFProject {
    func qualifiesForNavigationV2Experiment() -> Bool {
        switch self {
        case .wikipedia(let language):
            switch language.languageCode {
            case "fr", "ar", "de", "ja":
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
