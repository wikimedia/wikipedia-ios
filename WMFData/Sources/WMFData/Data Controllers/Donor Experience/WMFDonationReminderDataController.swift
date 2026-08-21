import Foundation

public struct WMFDonationReminder: Codable, Equatable, Sendable {

    public enum Trigger: Codable, Equatable, Sendable {
        case articlesRead(count: Int)
        case timeElapsed(days: Int)
    }

    public let trigger: Trigger
    public let amount: Decimal
    public let currencyCode: String
    public let createdDate: Date
    public var isEnabled: Bool

    public init(trigger: Trigger, amount: Decimal, currencyCode: String, createdDate: Date, isEnabled: Bool) {
        self.trigger = trigger
        self.amount = amount
        self.currencyCode = currencyCode
        self.createdDate = createdDate
        self.isEnabled = isEnabled
    }
}

public final class WMFDonationReminderDataController {

    public enum ExperimentAssignment: String, Sendable {
        case control
        case groupB
        case groupC
    }

    public enum ExperimentError: Error {
        case missingExperimentStore
        case unexpectedBucketValue
    }

    public static let shared = WMFDonationReminderDataController()

    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }
    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }

    private static let experimentGroupPercentage = 33

    private init() {}

    public func saveReminder(_ reminder: WMFDonationReminder) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.donationReminder.rawValue, value: reminder)
    }

    public func loadReminder() -> WMFDonationReminder? {
        return try? userDefaultsStore?.load(key: WMFUserDefaultsKey.donationReminder.rawValue)
    }

    public func clearReminder() {
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.donationReminder.rawValue)
    }

    // MARK: - Experiment Assignment

    public func clearExperimentAssignment() {
        guard let experimentStore else {
            return
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        try? experimentsDataController.resetExperiment(.donationReminder)
    }

    @discardableResult
    public func assignExperimentIfNeeded() throws -> ExperimentAssignment {
        guard let experimentStore else {
            throw ExperimentError.missingExperimentStore
        }

        let experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.donationReminder, withPercentage: Self.experimentGroupPercentage)

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
        guard let bucketValue = experimentsDataController.bucketForExperiment(.donationReminder) else {
            return nil
        }

        return ExperimentAssignment(bucketValue: bucketValue)
    }

    // Overrides assignment at read time only, so the persisted bucket survives
    // turning the developer setting back off.
    private var developerSettingsForcedAssignment: ExperimentAssignment? {
        WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment
    }
}

private extension WMFDonationReminderDataController.ExperimentAssignment {
    init?(bucketValue: WMFExperimentsDataController.BucketValue) {
        switch bucketValue {
        case .donationReminderControl:
            self = .control
        case .donationReminderGroupB:
            self = .groupB
        case .donationReminderGroupC:
            self = .groupC
        default:
            return nil
        }
    }
}
