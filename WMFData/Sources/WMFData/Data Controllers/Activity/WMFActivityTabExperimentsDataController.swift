import Foundation

public final class WMFActivityTabExperimentsDataController {
    public enum CustomError: Error {
        case invalidProject
        case invalidDate
        case alreadyAssignedBucket
        case missingAssignment
        case unexpectedAssignment
        case onFirstLaunch
    }

    public enum ActivityTabExperimentAssignment: Int {
        case control = 0
        case genericCTA = 1
        case suggestedEdit = 2
    }

    public static let shared = WMFActivityTabExperimentsDataController()
    
    private let experimentsDataController: WMFExperimentsDataController
    private let userDefaultsStore: WMFKeyValueStore?
    
    private let activityTabExperimentPercentage: Int = 33

    private var assignmentCache: ActivityTabExperimentAssignment?

    private init?(experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        guard let experimentStore else {
            return nil
        }
        self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        self.userDefaultsStore = userDefaultsStore
    }
    
    // We are assigning the experiment on the second launch. This gives us a chance to force a developer settings toggle during the first launch, then upon the 2nd launch the developer setting toggle can take effect during experiment assignment.
    private var hadFirstLaunch: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.activityTabHadFirstLaunch.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.activityTabHadFirstLaunch.rawValue, value: newValue)
        }
    }

    public func shouldAssignToBucket() -> Bool {
        return experimentsDataController.bucketForExperiment(.activityTab) == nil
    }

    public func assignActivityTabExperiment(project: WMFProject) throws -> ActivityTabExperimentAssignment {
        guard project.qualifiesActivityTabExperiment() else {
            throw CustomError.invalidProject
        }

        guard isBeforeEndDate else {
            reset()
            throw CustomError.invalidDate
        }
        
        guard hadFirstLaunch else {
            hadFirstLaunch = true
            throw CustomError.onFirstLaunch
        }

        if experimentsDataController.bucketForExperiment(.activityTab) != nil {
            throw CustomError.alreadyAssignedBucket
        }
        
        var developerSettingsForceValue: WMFExperimentsDataController.BucketValue?
        if WMFDeveloperSettingsDataController.shared.setActivityTabGroupA {
            developerSettingsForceValue = .activityTabGroupAControl
        } else if WMFDeveloperSettingsDataController.shared.setActivityTabGroupB {
            developerSettingsForceValue = .activityTabGroupBEdit
        } else if WMFDeveloperSettingsDataController.shared.setActivityTabGroupC {
            developerSettingsForceValue = .activityTabGroupCSuggestedEdit
        }

        let bucketValue = try experimentsDataController.determineBucketForExperiment(.activityTab, withPercentage: activityTabExperimentPercentage, forceValue: developerSettingsForceValue)

        let assignment: ActivityTabExperimentAssignment

        switch bucketValue {
        case .activityTabGroupAControl:
            assignment = .control
        case .activityTabGroupBEdit:
            assignment = .genericCTA
        case .activityTabGroupCSuggestedEdit:
            assignment = .suggestedEdit
        default:
            assignment = .control
        }

        self.assignmentCache = assignment
        return assignment
    }

    private func reset() {
        assignmentCache = nil
        try? experimentsDataController.resetExperiment(.activityTab)
        hadFirstLaunch = false
    }

    private var experimentEndDate: Date? { // TODO: - get real date
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 5
        dateComponents.day = 31
        return Calendar.current.date(from: dateComponents)
    }

    private var isBeforeEndDate: Bool {

        guard let experimentEndDate else {
            return false
        }

        return experimentEndDate >= Date()
    }

    public func getActivityTabExperimentAssignment() throws -> ActivityTabExperimentAssignment {
        let devSettingsController = WMFDeveloperSettingsDataController.shared

        if devSettingsController.setActivityTabGroupA {
            return .control
        } else if devSettingsController.setActivityTabGroupB {
            return .genericCTA
        } else if devSettingsController.setActivityTabGroupC {
            return .suggestedEdit
        }

        guard isBeforeEndDate else {
            throw CustomError.invalidDate
        }

        if let assignmentCache {
            return assignmentCache
        }

        guard let bucketValue = experimentsDataController.bucketForExperiment(.activityTab) else {
            throw CustomError.missingAssignment
        }

        let assignment: ActivityTabExperimentAssignment
        switch bucketValue {
        case .activityTabGroupAControl:
            assignment = .control
        case .activityTabGroupBEdit:
            assignment = .genericCTA
        case .activityTabGroupCSuggestedEdit:
            assignment = .suggestedEdit
        default:
            assignment = .control
        }

        self.assignmentCache = assignment
        return assignment
    }

}

private extension WMFProject {
    func qualifiesActivityTabExperiment() -> Bool {
        switch self {
        case .wikipedia(let language):
            switch language.languageCode {
            case "zh", "fr", "tr", "es", "test":
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}
