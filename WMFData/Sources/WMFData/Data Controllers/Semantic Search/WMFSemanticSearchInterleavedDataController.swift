import Foundation
import WMFTestKitchen

// Sendable: the only stored property is the immutable `stateLock`. All other state
// is read through the environment stores.
public final class WMFSemanticSearchInterleavedDataController: Sendable {

    public enum ExperimentAssignment: String, Sendable {
        case control
        case treatment
    }

    public enum ExperimentError: Error {
        case missingExperimentStore
        case missingUserDefaultsStore
        case unexpectedBucketValue
    }

    /// What the two retrievers do for a treatment reader, forced from developer settings so QA can
    /// reach every US-4 state. The `interleave_state` each one ends in is in the comment.
    public enum ForcedRetrievalScenario: String, Sendable, CaseIterable {
        /// `lexical_only_timeout`: semantic does not answer within the timeout.
        case semanticTimesOut
        /// `lexical_only_error`: semantic fails or the backend is unavailable.
        case semanticFails
        /// `lexical_only_rate_limited`: semantic is rate limited.
        case semanticRateLimited
        /// Semantic returns nothing and lexical has results. US-4 names no state for this.
        case semanticReturnsNothing
        /// `semantic_only`: lexical returns nothing and semantic has results.
        case lexicalReturnsNothing
        /// `none`: both return nothing and the existing empty state shows.
        case bothReturnNothing
        /// Both fail and the existing error state shows.
        case bothFail
    }

    public static let shared = WMFSemanticSearchInterleavedDataController()

    // MARK: - TODO
    //
    // Remote config. Today only the local developer flag turns the experiment on. The remote feature
    // config still needs to carry:
    // - an on/off switch (the kill switch). Off returns every reader to lexical search and keeps
    //   their arm, so turning it back on restores the same readers.
    // - the target languages (today fr, ar, ja from developer settings).
    // - the control percentage (today 50), if capacity limits the treatment share.
    //
    // Treatment share. 50/50 for now. If capacity limits it below 50%, the control arm stays the same
    // size as treatment and the remaining readers are in neither arm. The roll only has control and
    // treatment, so that needs a third outcome.
    //
    // Experiment name. `experimentName` is provisional.
    //
    // Dive. This experiment stays off while Dive (`isSemanticSearchEnabled`) is on. The Dive remote flag
    // is already off, so this only matters if both flags get turned on.

    public static let experimentName = "semantic-search-interleaving"
    private static let treatmentPercentage = 50
    private static let controlPercentage = 100 - treatmentPercentage
    public static let developerSettingsTargetLanguageCodes = ["fr", "ar", "ja"]

    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }
    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }

    private let stateLock = NSLock()

    private init() {}

    // MARK: - Availability

    public var isEnabled: Bool {
        let developerSettingsDataController = WMFDeveloperSettingsDataController.shared
        return !developerSettingsDataController.isSemanticSearchEnabled && developerSettingsDataController.enableSemanticSearchInterleaved
    }

    public var targetLanguageCodes: [String] {
        guard isEnabled else { return [] }
        let added = WMFDeveloperSettingsDataController.shared.addSemanticSearchInterleavedTargetLanguageCode
        return Self.developerSettingsTargetLanguageCodes + (added.map { [$0] } ?? [])
    }

    public func isTargetLanguage(languageCode: String) -> Bool {
        targetLanguageCodes.contains(languageCode)
    }

    public func isEligible(languageCode: String) -> Bool {
        isEnabled && isTargetLanguage(languageCode: languageCode)
    }

    public func shouldInterleave(languageCode: String) -> Bool {
        isEligible(languageCode: languageCode) && experimentAssignment == .treatment
    }

    public func forcedRetrievalScenario(languageCode: String) -> ForcedRetrievalScenario? {
        guard shouldInterleave(languageCode: languageCode) else { return nil }
        return WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedRetrievalScenario
    }

    // MARK: - Experiment Assignment

    @discardableResult
    public func enrollIfNeeded() throws -> ExperimentAssignment? {
        let appLanguageCodes = WMFDataEnvironment.current.appData.appLanguages.map(\.languageCode)
        return try enroll(isEligible: appLanguageCodes.contains { isEligible(languageCode: $0) })
    }

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
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.semanticSearchInterleaved, withPercentage: Self.controlPercentage)

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
        guard let bucketValue = experimentsDataController.bucketForExperiment(.semanticSearchInterleaved) else {
            return nil
        }

        return ExperimentAssignment(bucketValue: bucketValue)
    }

    public var experimentData: ExperimentData? {
        guard let experimentAssignment else { return nil }

        let coordinator = developerSettingsForcedAssignment == nil ? ExperimentData.coordinatorCustom : ExperimentData.coordinatorForced
        return ExperimentData(
            enrolled: Self.experimentName,
            assigned: experimentAssignment.rawValue,
            coordinator: coordinator,
            subjectId: WMFDataEnvironment.current.appInstallIDUtility?()
        )
    }

    public func clearExperimentAssignment() throws {
        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try experimentsDataController.resetExperiment(.semanticSearchInterleaved)
        try setHasSentExposure(false)
    }

    // MARK: - Exposure

    /// True when a search in `languageCode` should send the exposure event: the reader has a group and no
    /// exposure went out before. Each install sends one, in either arm.
    public func shouldSendExposure(languageCode: String) -> Bool {
        isEligible(languageCode: languageCode) && experimentAssignment != nil && !hasSentExposure
    }

    /// True after the exposure event went out on this install.
    public var hasSentExposure: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.semanticSearchInterleavedExposureSent.rawValue)) ?? false
    }

    public func markExposureSent() throws {
        try setHasSentExposure(true)
    }

    private func setHasSentExposure(_ hasSentExposure: Bool) throws {
        guard let userDefaultsStore else {
            throw ExperimentError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.semanticSearchInterleavedExposureSent.rawValue, value: hasSentExposure)
    }

    private var developerSettingsForcedAssignment: ExperimentAssignment? {
        WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment
    }
}

private extension WMFSemanticSearchInterleavedDataController.ExperimentAssignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .semanticSearchInterleavedControl:
            self = .control
        case .semanticSearchInterleavedGroupB:
            self = .treatment
        default:
            return nil
        }
    }
}
