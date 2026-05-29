import Foundation

extension DateFormatter {
    static let mediaWikiAPIDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
    
    static let metricsAPIDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    static let growthUserImpactAPIDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    public static let onThisDayAPIDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Month and Day only: e.g. `August 22`
    static let wmfMonthDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .none
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return formatter
    }()

    /// Parses a `yyyy-MM-dd` game date string and returns a localized "Month Day" string, e.g. `December 19`.
    public static func wmfMonthDayFromDailyGameDate(_ dateString: String) -> String {
        guard let date = onThisDayAPIDateFormatter.date(from: dateString) else { return dateString }
        return wmfMonthDayDateFormatter.string(from: date)
    }
}
