import Foundation
import WMFTestKitchen

/// The A/B test of the cards on the Year in Review end screen (T441006), the same test as Android's
/// `YearInReviewEndScreenABTest`. Group B also sees the games card and the interests card.
///
/// Only readers whose primary app language has the Which Came First game are assigned a group.
/// The bucket is rolled when the end screen is built, so its cards do not change while the reader
/// swipes to it. The reader is enrolled when the exposure event goes out, on the first impression
/// of the end screen. After that the reader stays in the test, even if the primary app language
/// changes, so the events of one install do not leave the test.
///
/// Not a singleton: it keeps no state in memory. All state is in the stores.
public struct WMFYearInReviewEndCardsDataController: Sendable {

    public enum Assignment: String, Sendable, CaseIterable {
        case control
        case groupB
    }

    /// The extra cards that the end screen shows.
    public struct EngagementCards: Sendable, Equatable {
        public let showsGamesCard: Bool
        public let showsInterestsCard: Bool

        static let none = EngagementCards(showsGamesCard: false, showsInterestsCard: false)
    }

    public enum CustomError: Error {
        case missingExperimentStore
        case missingUserDefaultsStore
        case unexpectedBucketValue
    }

    /// The name of the experiment in the events. The same name as on Android.
    public static let experimentName = "year-in-review-end-screen"

    /// Half of the qualified readers stay in the control group.
    static let controlPercentage = 50

    /// Two calls at the same time must not roll two buckets.
    private static let rollLock = NSLock()

    private let injectedExperimentStore: WMFKeyValueStore?
    private let injectedUserDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataController
    private let primaryAppLanguage: @Sendable () -> WMFLanguage?

    private var experimentStore: WMFKeyValueStore? { injectedExperimentStore ?? WMFDataEnvironment.current.sharedCacheStore }
    private var userDefaultsStore: WMFKeyValueStore? { injectedUserDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore }

    /// Nil stores read the environment's stores at call time.
    public init() {
        self.init(experimentStore: nil)
    }

    init(
        experimentStore: WMFKeyValueStore?,
        userDefaultsStore: WMFKeyValueStore? = nil,
        developerSettingsDataController: WMFDeveloperSettingsDataController = .shared,
        primaryAppLanguage: @escaping @Sendable () -> WMFLanguage? = { WMFDataEnvironment.current.primaryAppLanguage }
    ) {
        self.injectedExperimentStore = experimentStore
        self.injectedUserDefaultsStore = userDefaultsStore
        self.developerSettingsDataController = developerSettingsDataController
        self.primaryAppLanguage = primaryAppLanguage
    }

    // MARK: - Qualification

    /// True when the primary app language has the Which Came First game.
    public var isQualified: Bool {
        guard let language = primaryAppLanguage() else {
            return false
        }
        return WMFGamesDataController.isWhichCameFirstSupported(project: .wikipedia(language))
    }

    // MARK: - Cards

    /// Rolls the bucket if the reader qualifies and has none, and returns the extra cards for the end
    /// screen. Group B gets the games card only while the primary app language has the game, and
    /// the interests card always.
    public func assignEngagementCardsIfNeeded() throws -> EngagementCards {
        try assignIfNeeded()
        guard assignment == .groupB else {
            return .none
        }
        return EngagementCards(showsGamesCard: isQualified, showsInterestsCard: true)
    }

    // MARK: - Assignment

    /// Rolls the bucket for a qualified reader on the first call. Returns the group, as `assignment` does.
    @discardableResult
    func assignIfNeeded() throws -> Assignment? {
        if isQualified {
            Self.rollLock.lock()
            defer { Self.rollLock.unlock() }

            guard let experimentStore else {
                throw CustomError.missingExperimentStore
            }

            let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
            let bucketValue = try experimentsDataController.determineBucketForExperiment(.yirEndCards, withPercentage: Self.controlPercentage)
            guard Assignment(bucketValue: bucketValue) != nil else {
                throw CustomError.unexpectedBucketValue
            }
        }

        return assignment
    }

    /// The group of the reader, without rolling a bucket. Nil when the reader has no bucket, or does
    /// not qualify and was never enrolled.
    public var assignment: Assignment? {
        guard isQualified || hasSentExposure else {
            return nil
        }

        if let developerSettingsForcedAssignment {
            return developerSettingsForcedAssignment
        }

        guard let experimentStore else {
            return nil
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        guard let bucketValue = experimentsDataController.bucketForExperiment(.yirEndCards) else {
            return nil
        }

        return Assignment(bucketValue: bucketValue)
    }

    /// The experiment fields of the Year in Review events. Nil when the reader has no group.
    public var experimentData: ExperimentData? {
        guard let assignment else { return nil }

        let coordinator = developerSettingsForcedAssignment == nil ? ExperimentData.coordinatorCustom : ExperimentData.coordinatorForced
        return ExperimentData(
            enrolled: Self.experimentName,
            assigned: assignment == .groupB ? "treatment" : "control",
            coordinator: coordinator,
            subjectId: WMFDataEnvironment.current.appInstallIDUtility?()
        )
    }

    public func clearAssignment() throws {
        guard let experimentStore else {
            throw CustomError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try experimentsDataController.resetExperiment(.yirEndCards)
        try setHasSentExposure(false)
    }

    /// Sets the developer settings override. Turning it off also clears the bucket and the exposure
    /// flag, so the next end screen rolls a real bucket and sends a real exposure. Otherwise the
    /// forced exposure would use up the one exposure of the install.
    public func setDeveloperSettingsForcedAssignment(_ newValue: Assignment?) throws {
        let oldValue = developerSettingsForcedAssignment
        developerSettingsDataController.forceYiREndCardsExperimentAssignment = newValue
        if oldValue != nil, newValue == nil {
            try clearAssignment()
        }
    }

    // MARK: - Exposure

    /// Call on each impression of the end screen, and only there, so that only readers who saw the
    /// end screen are enrolled. Calls `sendExposure` once per install, in both groups, then records it.
    public func recordEndScreenImpression(sendExposure: (ExperimentData) -> Void) throws {
        guard !hasSentExposure, let experimentData else {
            return
        }
        sendExposure(experimentData)
        try setHasSentExposure(true)
    }

    public var hasSentExposure: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.yirEndCardsExposureSent.rawValue)) ?? false
    }

    private func setHasSentExposure(_ hasSentExposure: Bool) throws {
        guard let userDefaultsStore else {
            throw CustomError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.yirEndCardsExposureSent.rawValue, value: hasSentExposure)
    }

    // Overrides the assignment at read time only, so the persisted bucket survives turning the
    // developer setting back off.
    private var developerSettingsForcedAssignment: Assignment? {
        developerSettingsDataController.forceYiREndCardsExperimentAssignment
    }
}

private extension WMFYearInReviewEndCardsDataController.Assignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .yirEndCardsControl:
            self = .control
        case .yirEndCardsGroupB:
            self = .groupB
        default:
            return nil
        }
    }
}
