import Foundation

/// Decides when the Discover reading list is due for a new generation. A new list is due the
/// first time the app opens in a new period: a new day, a week that starts on Monday, or a month.
public enum WMFDiscoverSchedule {

    /// True when a new list is due. A list that was never generated is always due.
    public static func isGenerationDue(cadence: WMFDiscoverCadence, lastGeneratedDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let lastGeneratedDate else {
            return true
        }

        guard let periodStart = periodStart(for: cadence, containing: now, calendar: calendar) else {
            return false
        }

        return lastGeneratedDate < periodStart
    }

    private static func periodStart(for cadence: WMFDiscoverCadence, containing date: Date, calendar: Calendar) -> Date? {
        switch cadence {
        case .daily:
            return calendar.startOfDay(for: date)
        case .weekly:
            // The week starts on Monday, whatever the locale's first weekday is.
            var mondayCalendar = calendar
            mondayCalendar.firstWeekday = 2
            return mondayCalendar.dateInterval(of: .weekOfYear, for: date)?.start
        case .monthly:
            return calendar.dateInterval(of: .month, for: date)?.start
        }
    }
}
