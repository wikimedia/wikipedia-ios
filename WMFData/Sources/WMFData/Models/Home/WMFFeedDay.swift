import Foundation

/// One calendar day of the Home feed, in the device's time zone.
///
/// The feed API, the On this day API and the Picture of the day gallery all ask for the local
/// day, so this is the one place a `Date` becomes a feed day. Two dates on the same local day
/// give the same value, so a day compares and hashes without `startOfDay` calls.
public struct WMFFeedDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date) {
        let components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 1, month: components.month ?? 1, day: components.day ?? 1)
    }

    public static func today(now: Date = Date()) -> WMFFeedDay {
        WMFFeedDay(date: now)
    }

    /// Noon of the day. Noon, not midnight, so that a daylight saving change or a small time zone
    /// change cannot move the date into the day before or after.
    public var date: Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    public func adding(days: Int) -> WMFFeedDay {
        guard let date = Self.calendar.date(byAdding: .day, value: days, to: date) else { return self }
        return WMFFeedDay(date: date)
    }

    /// `yyyy-MM-dd`, for keys and logs.
    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: WMFFeedDay, rhs: WMFFeedDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Gregorian like the feed requests, so a device set to another calendar asks for the same
    /// day. The time zone is the device's, read each time, so a time zone change applies at once.
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
}
