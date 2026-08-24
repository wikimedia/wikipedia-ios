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

    public init(trigger: Trigger, amount: Decimal, currencyCode: String, createdDate: Date, isEnabled: Bool, progress: Progress? = nil) {
        self.trigger = trigger
        self.amount = amount
        self.currencyCode = currencyCode
        self.createdDate = createdDate
        self.isEnabled = isEnabled
        self.progress = progress
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
}

public final class WMFDonationReminderDataController {

    public static let shared = WMFDonationReminderDataController()

    private var userDefaultsStore: WMFKeyValueStore? { WMFDataEnvironment.current.userDefaultsStore }

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
}
