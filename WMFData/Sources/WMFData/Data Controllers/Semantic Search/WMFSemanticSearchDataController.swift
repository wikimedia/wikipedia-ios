import Foundation
import WMFTestKitchen

// Sendable: the only stored property is the immutable `stateLock`. All other state
// is read through the environment stores.
public final class WMFSemanticSearchDataController: Sendable {

    public enum ExperimentAssignment: String, Sendable {
        case control
        case groupB
    }

    public enum ExperimentError: Error {
        case missingExperimentStore
        case missingUserDefaultsStore
        case unexpectedBucketValue
    }

    public static let shared = WMFSemanticSearchDataController()

    /// The target languages while the developer setting is on and the remote config has none.
    public static let developerSettingsTargetLanguageCodes = ["fr", "ar", "ja"]

    private static let experimentControlPercentage = 50
    /// The name of the experiment in the `experiments.enrolled` column of the search events.
    static let experimentName = "semantic-search-phase-2"

    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }
    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }

    private let stateLock = NSLock()

    private init() {}

    // MARK: - Availability

    /// True when the semantic search entry point can render for a search in `languageCode`.
    public func isEntryPointAvailable(languageCode: String) -> Bool {
        guard isEligible(languageCode: languageCode), !isEntryPointHidden else {
            return false
        }

        return experimentAssignment == .groupB
    }

    public var isEntryPointHidden: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.semanticSearchEntryPointHidden.rawValue)) ?? false
    }

    /// True when Settings offers the control that shows or hides the entry point: the reader is
    /// in group B while the feature is on.
    public var isSettingsEntryAvailable: Bool {
        guard WMFDeveloperSettingsDataController.shared.isSemanticSearchEnabled else {
            return false
        }

        return experimentAssignment == .groupB
    }

    public func setEntryPointHidden(_ isHidden: Bool) throws {
        guard let userDefaultsStore else {
            throw ExperimentError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchEntryPointHidden.rawValue, value: isHidden)
    }

    /// True after the reader opened semantic search from the entry point at least once. The entry
    /// point shows its call to action only before that.
    public var hasUsedEntryPoint: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.semanticSearchEntryPointUsed.rawValue)) ?? false
    }

    public func markEntryPointUsed() throws {
        guard let userDefaultsStore else {
            throw ExperimentError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchEntryPointUsed.rawValue, value: true)
    }

    /// Debugging convenience: forgets the hidden state and the first use, so the entry point shows
    /// again with its call to action.
    public func resetEntryPointState() throws {
        guard let userDefaultsStore else {
            throw ExperimentError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchEntryPointHidden.rawValue, value: false)
        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchEntryPointUsed.rawValue, value: false)
    }

    /// True when a search in `languageCode` can enroll the reader in the experiment.
    public func isEligible(languageCode: String) -> Bool {
        guard WMFDeveloperSettingsDataController.shared.isSemanticSearchEnabled else {
            return false
        }

        return isTargetLanguage(languageCode: languageCode)
    }

    public func isTargetLanguage(languageCode: String) -> Bool {
        targetLanguageCodes.contains(languageCode)
    }

    /// The languages from `iosv1.semanticSearchLanguagesv2` in the remote feature config. When the
    /// remote config has none, the developer settings languages apply while the "Enable Semantic
    /// Search" developer setting is on. Otherwise no language is targeted.
    public var targetLanguageCodes: [String] {
        let developerSettingsDataController = WMFDeveloperSettingsDataController.shared
        let remoteLanguageCodes = developerSettingsDataController.loadFeatureConfig()?.ios.semanticSearchLanguages ?? []
        guard remoteLanguageCodes.isEmpty, developerSettingsDataController.enableSemanticSearch else {
            return remoteLanguageCodes
        }
        return Self.developerSettingsTargetLanguageCodes
    }

    // MARK: - Experiment Assignment

    /// Rolls the experiment bucket when search opens for a reader with a target wiki among their
    /// app languages, as on Android, and returns the persisted bucket after that. The search can
    /// then be on any wiki: every event of it carries the group. Returns nil for other readers.
    @discardableResult
    public func enrollIfNeeded() throws -> ExperimentAssignment? {
        let appLanguageCodes = WMFDataEnvironment.current.appData.appLanguages.map(\.languageCode)
        return try enroll(isEligible: appLanguageCodes.contains { isEligible(languageCode: $0) })
    }

    /// Rolls the experiment bucket for a search in a target language when the reader has none
    /// yet, for example a search on a wiki outside their app languages, and returns the persisted
    /// bucket after that. Returns nil when the search is not eligible.
    @discardableResult
    public func enrollIfNeeded(languageCode: String) throws -> ExperimentAssignment? {
        try enroll(isEligible: isEligible(languageCode: languageCode))
    }

    private func enroll(isEligible: Bool) throws -> ExperimentAssignment? {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard isEligible else {
            return nil
        }

        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: Self.experimentControlPercentage)

        guard let assignment = ExperimentAssignment(bucketValue: bucketValue) else {
            throw ExperimentError.unexpectedBucketValue
        }

        return developerSettingsForcedAssignment ?? assignment
    }

    /// The experiment fields of every search event, in the shape the Android app sends. Nil before
    /// the reader has a group.
    public var experimentData: ExperimentData? {
        guard let experimentAssignment else { return nil }

        let coordinator = developerSettingsForcedAssignment == nil ? ExperimentData.coordinatorCustom : ExperimentData.coordinatorForced
        return ExperimentData(
            enrolled: Self.experimentName,
            assigned: experimentAssignment == .groupB ? "treatment" : "control",
            coordinator: coordinator,
            subjectId: WMFDataEnvironment.current.appInstallIDUtility?()
        )
    }

    public var experimentAssignment: ExperimentAssignment? {
        if let developerSettingsForcedAssignment {
            return developerSettingsForcedAssignment
        }

        guard let experimentStore else {
            return nil
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        guard let bucketValue = experimentsDataController.bucketForExperiment(.semanticSearch) else {
            return nil
        }

        return ExperimentAssignment(bucketValue: bucketValue)
    }

    public func clearExperimentAssignment() throws {
        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try experimentsDataController.resetExperiment(.semanticSearch)
        try setHasSentExposure(false)
    }

    // MARK: - Exposure

    /// True when a search in `languageCode` should send the exposure event: the reader has a
    /// group and no exposure went out before. Each install sends one. A reader who hid the entry
    /// point in Settings before their first search on a target wiki is not exposed, as on Android.
    public func shouldSendExposure(languageCode: String) -> Bool {
        isEligible(languageCode: languageCode) && experimentAssignment != nil && !isEntryPointHidden && !hasSentExposure
    }

    /// True after the exposure event went out on this install.
    public var hasSentExposure: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.semanticSearchExposureSent.rawValue)) ?? false
    }

    public func markExposureSent() throws {
        try setHasSentExposure(true)
    }

    private func setHasSentExposure(_ hasSentExposure: Bool) throws {
        guard let userDefaultsStore else {
            throw ExperimentError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchExposureSent.rawValue, value: hasSentExposure)
    }

    // Overrides assignment at read time only, so the persisted bucket survives
    // turning the developer setting back off.
    private var developerSettingsForcedAssignment: ExperimentAssignment? {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment
    }
}

private extension WMFSemanticSearchDataController.ExperimentAssignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .semanticSearchControl:
            self = .control
        case .semanticSearchGroupB:
            self = .groupB
        default:
            return nil
        }
    }
}
