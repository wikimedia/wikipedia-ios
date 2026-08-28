import Foundation

public struct WMFDonationReminder: Codable, Equatable, Sendable {

    public enum Trigger: Codable, Equatable, Sendable {
        case articlesRead(count: Int)
        case timeElapsed(days: Int)
    }

    public struct Progress: Codable, Equatable, Sendable {
        public var currentCycleStartDate: Date
        public var timesReminderShown: Int
        public var lastReminderShownDate: Date?
        public var goalReachedCount: Int

        private enum CodingKeys: String, CodingKey {
            case currentCycleStartDate
            case timesReminderShown
            case lastReminderShownDate
            case goalReachedCount
        }

        public init(currentCycleStartDate: Date, timesReminderShown: Int, lastReminderShownDate: Date? = nil, goalReachedCount: Int = 0) {
            self.currentCycleStartDate = currentCycleStartDate
            self.timesReminderShown = timesReminderShown
            self.lastReminderShownDate = lastReminderShownDate
            self.goalReachedCount = goalReachedCount
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentCycleStartDate = try container.decode(Date.self, forKey: .currentCycleStartDate)
            timesReminderShown = try container.decode(Int.self, forKey: .timesReminderShown)
            lastReminderShownDate = try container.decodeIfPresent(Date.self, forKey: .lastReminderShownDate)
            goalReachedCount = try container.decodeIfPresent(Int.self, forKey: .goalReachedCount) ?? 0
        }
    }

    public let trigger: Trigger
    public let amount: Decimal
    public let currencyCode: String
    public let createdDate: Date
    public var isEnabled: Bool
    public var progress: Progress?

    public var experimentEndDate: Date?

    public init(
        trigger: Trigger,
        amount: Decimal,
        currencyCode: String,
        createdDate: Date,
        isEnabled: Bool,
        progress: Progress? = nil,
        experimentEndDate: Date? = nil
    ) {
        self.trigger = trigger
        self.amount = amount
        self.currencyCode = currencyCode
        self.createdDate = createdDate
        self.isEnabled = isEnabled
        self.progress = progress
        self.experimentEndDate = experimentEndDate
    }

    public var currentCycleStartDate: Date {
        progress?.currentCycleStartDate ?? createdDate
    }

    public var timesReminderShown: Int {
        progress?.timesReminderShown ?? 0
    }

    public var lastReminderShownDate: Date? {
        progress?.lastReminderShownDate
    }

    public var goalReachedCount: Int {
        progress?.goalReachedCount ?? 0
    }

    public func isExpired(currentDate: Date = Date()) -> Bool {
        guard let experimentEndDate else {
            return false
        }
        return currentDate > experimentEndDate
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

    public static let experimentPresetAmounts: [Decimal] = [1, 3, 5]

    #if DEBUG
    public static let minimumSecondsForArticleRead = 1
    #else
    public static let minimumSecondsForArticleRead = 5
    #endif

    private static let maximumIgnoredReminderImpressions = 2

    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }
    private var experimentStore: WMFKeyValueStore? { WMFDataEnvironment.current.sharedCacheStore }

    private static let experimentGroupPercentage = 33

    private let stateLock = NSLock()

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

    public func isReminderSettingsEntryAvailable(currentDate: Date = Date()) -> Bool {
        guard WMFDeveloperSettingsDataController.shared.enableDonationReminder else {
            return false
        }

        switch experimentAssignment {
        case .groupB, .groupC:
            break
        default:
            return false
        }

        guard let reminder = loadReminder() else {
            return false
        }

        return !reminder.isExpired(currentDate: currentDate)
    }

    // MARK: - Follow-up Reminder Cycle

    public func articlesReadInCurrentCycle(currentDate: Date = Date()) async throws -> Int {
        guard let reminder = loadReminder() else {
            return 0
        }

        let pageViewsDataController = try WMFPageViewsDataController()
        return try await pageViewsDataController.fetchPageViewsCount(startDate: reminder.currentCycleStartDate, endDate: currentDate, minimumDurationSeconds: Self.minimumSecondsForArticleRead)
    }

    public func shouldShowFollowUpReminder(currentDate: Date = Date()) async throws -> Bool {
        guard WMFDeveloperSettingsDataController.shared.enableDonationReminder,
              let reminder = loadReminder(),
              reminder.isEnabled,
              case .articlesRead(count: let articlesReadGoal) = reminder.trigger else {
            return false
        }

        guard passesDailyLimit(reminder: reminder, currentDate: currentDate) else {
            return false
        }

        if reminder.timesReminderShown == 1 {
            return true
        }

        let articlesRead = try await articlesReadInCurrentCycle(currentDate: currentDate)
        return articlesRead >= articlesReadGoal
    }

    public func claimFollowUpReminderImpression(currentDate: Date = Date()) async throws -> WMFDonationReminder? {
        guard try await shouldShowFollowUpReminder(currentDate: currentDate) else {
            return nil
        }

        return claimValidatedImpression(currentDate: currentDate)
    }

    private func claimValidatedImpression(currentDate: Date) -> WMFDonationReminder? {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard var reminder = loadReminder(),
              reminder.isEnabled,
              passesDailyLimit(reminder: reminder, currentDate: currentDate) else {
            return nil
        }

        applyReminderShown(to: &reminder, currentDate: currentDate)
        saveReminder(reminder)
        return reminder
    }

    public func recordFollowUpReminderShown(currentDate: Date = Date()) {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard var reminder = loadReminder() else {
            return
        }

        applyReminderShown(to: &reminder, currentDate: currentDate)
        saveReminder(reminder)
    }

    private func passesDailyLimit(reminder: WMFDonationReminder, currentDate: Date) -> Bool {
        guard let lastReminderShownDate = reminder.lastReminderShownDate,
              Calendar.current.isDate(lastReminderShownDate, inSameDayAs: currentDate) else {
            return true
        }

        return WMFDeveloperSettingsDataController.shared.bypassDonationReminderDailyLimit
    }

    private func applyReminderShown(to reminder: inout WMFDonationReminder, currentDate: Date) {
        if reminder.timesReminderShown == 1 {
            reminder.progress?.timesReminderShown = 2
            reminder.progress?.lastReminderShownDate = currentDate
        } else {
            reminder.progress = WMFDonationReminder.Progress(currentCycleStartDate: currentDate, timesReminderShown: 1, lastReminderShownDate: currentDate, goalReachedCount: reminder.goalReachedCount + 1)
        }
    }

    public func closeFollowUpReminderWindow() {
        guard var reminder = loadReminder(),
              var progress = reminder.progress else {
            return
        }

        progress.timesReminderShown = Self.maximumIgnoredReminderImpressions
        reminder.progress = progress
        saveReminder(reminder)
    }

    public var isFollowUpReminderWindowClosed: Bool {
        guard let reminder = loadReminder() else { return false }

        return reminder.timesReminderShown >= Self.maximumIgnoredReminderImpressions
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

        stateLock.lock()
        defer { stateLock.unlock() }

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
