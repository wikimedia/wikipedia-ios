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

public final class WMFDonationReminderDataController: Sendable {

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
