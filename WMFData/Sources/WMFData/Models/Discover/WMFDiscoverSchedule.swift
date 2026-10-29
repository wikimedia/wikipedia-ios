import Foundation

/// Decides when the Discover reading list is due for a new generation. Mirrors the Android task:
/// at least one day since the last generation, and the cadence's day has arrived.
public enum WMFDiscoverSchedule {

    static let minimumSecondsBetweenGenerations: TimeInterval = 60 * 60 * 24

    /// True when a new list is due. A list that was never generated is always due.
    public static func isGenerationDue(cadence: WMFDiscoverCadence, lastGeneratedDate: Date?, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let lastGeneratedDate else {
            return true
        }

        guard now.timeIntervalSince(lastGeneratedDate) >= minimumSecondsBetweenGenerations else {
            return false
        }

        switch cadence {
        case .daily:
            return true
        case .weekly:
            // Android regenerates on Monday, whatever the locale's first weekday is.
            return calendar.component(.weekday, from: now) == 2
        case .monthly:
            return calendar.component(.day, from: now) == 1
        }
    }
}
