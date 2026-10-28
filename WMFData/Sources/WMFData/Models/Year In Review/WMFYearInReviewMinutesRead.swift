import Foundation

/// How a reader's total reading time compares to a known duration, on the minutes read slide.
/// The thresholds are shared with Android, so they must match the shared copy spreadsheet.
public enum WMFYearInReviewMinutesReadComparison: Equatable, Sendable {
    case hummingbird
    case sunlight
    case egg
    case fallAsleep
    case sitcom
    case spaceStation
    case marathon
    case nightSleep
    case honeybee
    case days(Int)

    static let minutesPerDay = 1440

    /// The most days that the comparison names.
    public static let maximumDayCount = 300

    /// The smallest number of minutes that shows the days comparison. The day count is the minutes
    /// divided by the minutes in a day, rounded down.
    static let daysThresholdMinutes = 2800

    /// Each entry is the smallest number of minutes that shows the comparison, from smallest to largest.
    private static let thresholds: [(minutes: Int, comparison: WMFYearInReviewMinutesReadComparison)] = [
        (1, .hummingbird),
        (9, .sunlight),
        (13, .egg),
        (19, .fallAsleep),
        (31, .sitcom),
        (93, .spaceStation),
        (121, .marathon),
        (540, .nightSleep),
        (1441, .honeybee)
    ]

    /// The comparison for the largest threshold that `minutes` is equal to or more than.
    /// `nil` for less than one minute.
    public static func comparison(forMinutes minutes: Int) -> WMFYearInReviewMinutesReadComparison? {
        if minutes >= daysThresholdMinutes {
            return .days(min(minutes / minutesPerDay, maximumDayCount))
        }
        return thresholds.last(where: { minutes >= $0.minutes })?.comparison
    }
}

extension WMFYearInReviewReadData {
    /// The reader must have read for at least this number of minutes, which is 60 seconds.
    public static let minimumMinutesRead = 1

    /// More minutes than this are most likely an error, so the slide does not show.
    public static let maximumMinutesRead = 300_000

    /// If false, do not show the minutes read slide. This slide has no empty version.
    public var isMinutesReadEligible: Bool {
        minutesRead >= Self.minimumMinutesRead && minutesRead <= Self.maximumMinutesRead
    }
}
