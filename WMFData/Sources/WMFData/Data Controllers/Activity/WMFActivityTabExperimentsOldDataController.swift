import Foundation

public final class WMFActivityTabExperimentsOldDataController {
    public enum CustomError: Error {
        case invalidProject
        case invalidDate
        case alreadyAssignedBucket
        case missingAssignment
        case unexpectedAssignment
        case onFirstLaunch
    }

    public enum OldActivityTabExperimentAssignment: Int {
        case control = 0
        case genericCTA = 1
        case suggestedEdit = 2
    }

    public static let shared = WMFActivityTabExperimentsOldDataController()
    
    private let experimentsDataController: WMFExperimentsDataController
    private let userDefaultsStore: WMFKeyValueStore?
    
    private let activityTabExperimentPercentage: Int = 33

    private var assignmentCache: OldActivityTabExperimentAssignment?

    private init?(experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        guard let experimentStore else {
            return nil
        }
        self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        self.userDefaultsStore = userDefaultsStore
    }

    public func shouldAssignToBucket() -> Bool {
        return experimentsDataController.bucketForExperiment(.oldActivityTabExperiment) == nil
    }

    public func assignActivityTabExperiment(project: WMFProject) throws -> OldActivityTabExperimentAssignment {
        guard project.qualifiesActivityTabExperiment() else {
            throw CustomError.invalidProject
        }

        guard isBeforeEndDate else {
            reset()
            throw CustomError.invalidDate
        }

        if experimentsDataController.bucketForExperiment(.oldActivityTabExperiment) != nil {
            throw CustomError.alreadyAssignedBucket
        }

        let bucketValue = try experimentsDataController.determineBucketForExperiment(.oldActivityTabExperiment, withPercentage: activityTabExperimentPercentage)

        let assignment: OldActivityTabExperimentAssignment

        switch bucketValue {
        case .activityTabGroupAControl:
            assignment = .control
        case .activityTabGroupBEdit:
            assignment = .genericCTA
        case .activityTabGroupCSuggestedEdit:
            assignment = .suggestedEdit
        default:
            throw CustomError.unexpectedAssignment
            
        }

        self.assignmentCache = assignment
        return assignment
    }

    private func reset() {
        assignmentCache = nil
        try? experimentsDataController.resetExperiment(.oldActivityTabExperiment)
    }

    private var experimentEndDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 6
        dateComponents.day = 15
        return Calendar.current.date(from: dateComponents)
    }

    private var isBeforeEndDate: Bool {

        guard let experimentEndDate else {
            return false
        }

        return experimentEndDate >= Date()
    }

    public func getActivityTabExperimentAssignment(project: WMFProject) throws -> OldActivityTabExperimentAssignment {

        let devSettingsController = WMFDeveloperSettingsDataController.shared

        if devSettingsController.setActivityTabGroupA {
            return .control
        } else if devSettingsController.setActivityTabGroupB {
            return .genericCTA
        } else if devSettingsController.setActivityTabGroupC {
            return .suggestedEdit
        }

        guard project.qualifiesActivityTabExperiment() else {
            throw CustomError.invalidProject
        }

        guard isBeforeEndDate else {
            throw CustomError.invalidDate
        }

        if let assignmentCache {
            return assignmentCache
        }

        guard let bucketValue = experimentsDataController.bucketForExperiment(.oldActivityTabExperiment) else {
            throw CustomError.missingAssignment
        }

        let assignment: OldActivityTabExperimentAssignment
        switch bucketValue {
        case .activityTabGroupAControl:
            assignment = .control
        case .activityTabGroupBEdit:
            assignment = .genericCTA
        case .activityTabGroupCSuggestedEdit:
            assignment = .suggestedEdit
        default:
            throw CustomError.unexpectedAssignment
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
