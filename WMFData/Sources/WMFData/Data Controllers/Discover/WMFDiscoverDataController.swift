import Foundation

// Sendable: the only stored property is the immutable `stateLock`. All other state
// is read through the environment stores.
public final class WMFDiscoverDataController: Sendable {

    public enum ExperimentAssignment: String, Sendable {
        case control
        case groupB
    }

    public enum DiscoverError: Error {
        case missingExperimentStore
        case missingUserDefaultsStore
        case unexpectedBucketValue
    }

    public static let shared = WMFDiscoverDataController()

    /// Applies until the remote feature config carries `iosv1.discoverExperimentControlPercentage`.
    /// Everyone stays in the control group, so a release without the remote key exposes nobody.
    public static let defaultExperimentControlPercentage = 100

    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }
    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }

    private let stateLock = NSLock()

    private init() {}

    // MARK: - Availability

    /// True while the developer setting that gates the whole feature is on.
    public var isEnabled: Bool {
        WMFDeveloperSettingsDataController.shared.enableDiscover
    }

    /// True when the Saved tab shows the onboarding announcement card and its badge: the feature
    /// is on, the reader is in group B and the card has not gone away yet.
    public var shouldShowAnnouncement: Bool {
        guard isEnabled, experimentAssignment == .groupB else {
            return false
        }

        return !hasDismissedAnnouncement
    }

    // MARK: - Announcement

    /// True once the reader tapped No thanks on the announcement card or turned Discover on.
    public var hasDismissedAnnouncement: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.discoverOnboardingAnnouncementDismissed.rawValue)) ?? false
    }

    public func markAnnouncementDismissed() throws {
        guard let userDefaultsStore else {
            throw DiscoverError.missingUserDefaultsStore
        }

        try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverOnboardingAnnouncementDismissed.rawValue, value: true)
        NotificationCenter.default.post(name: WMFNSNotification.discoverAnnouncementStateDidChange, object: nil)
    }

    /// Debugging convenience: shows the announcement card again.
    public func resetAnnouncement() throws {
        guard let userDefaultsStore else {
            throw DiscoverError.missingUserDefaultsStore
        }

        try userDefaultsStore.remove(key: WMFUserDefaultsKey.discoverOnboardingAnnouncementDismissed.rawValue)
        NotificationCenter.default.post(name: WMFNSNotification.discoverAnnouncementStateDidChange, object: nil)
    }

    // MARK: - Experiment Assignment

    /// The share of readers in the control group, 0 to 100, from the remote feature config when
    /// it carries the key. Changing the share re-rolls every reader's bucket.
    public var experimentControlPercentage: Int {
        let remotePercentage = WMFDeveloperSettingsDataController.shared.loadFeatureConfig()?.ios.discoverExperimentControlPercentage
        guard let remotePercentage, (0...100).contains(remotePercentage) else {
            return Self.defaultExperimentControlPercentage
        }

        return remotePercentage
    }

    /// Rolls the experiment bucket on the first call, and returns the persisted bucket after that.
    @discardableResult
    public func assignExperimentIfNeeded() throws -> ExperimentAssignment {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard let experimentStore else {
            throw DiscoverError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.discover, withPercentage: experimentControlPercentage)

        guard let assignment = ExperimentAssignment(bucketValue: bucketValue) else {
            throw DiscoverError.unexpectedBucketValue
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
        guard let bucketValue = experimentsDataController.bucketForExperiment(.discover) else {
            return nil
        }

        return ExperimentAssignment(bucketValue: bucketValue)
    }

    public func clearExperimentAssignment() throws {
        guard let experimentStore else {
            throw DiscoverError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try experimentsDataController.resetExperiment(.discover)
    }

    // Overrides assignment at read time only, so the persisted bucket survives
    // turning the developer setting back off.
    private var developerSettingsForcedAssignment: ExperimentAssignment? {
        WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment
    }
}

private extension WMFDiscoverDataController.ExperimentAssignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .discoverControl:
            self = .control
        case .discoverGroupB:
            self = .groupB
        default:
            return nil
        }
    }
}
