import Foundation

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

    // TODO: Remove when the `iosv1.semanticSearchLanguages` in the remote feature config is available.
    public static let defaultTargetLanguageCodes = ["fr", "ar", "ja"]

    private static let experimentControlPercentage = 50

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
        guard WMFDeveloperSettingsDataController.shared.enableSemanticSearch else {
            return false
        }

        return isTargetLanguage(languageCode: languageCode)
    }

    public func isTargetLanguage(languageCode: String) -> Bool {
        targetLanguageCodes.contains(languageCode)
    }

    /// The languages from `iosv1.semanticSearchLanguages` in the remote feature config. Until the
    /// remote config has the key, the default target languages apply.
    public var targetLanguageCodes: [String] {
        let remoteLanguageCodes = WMFDeveloperSettingsDataController.shared.loadFeatureConfig()?.ios.semanticSearchLanguages ?? []
        return remoteLanguageCodes.isEmpty ? Self.defaultTargetLanguageCodes : remoteLanguageCodes
    }

    // MARK: - Experiment Assignment

    /// Rolls the experiment bucket the first time a reader runs an eligible search, and returns
    /// the persisted bucket after that. Returns nil when the search is not eligible.
    @discardableResult
    public func assignExperimentIfNeeded(languageCode: String) throws -> ExperimentAssignment? {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard isEligible(languageCode: languageCode) else {
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
