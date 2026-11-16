import Foundation

/// The parts of the day on the Year in Review reading pattern slide. The hours are in the time zone
/// of the device, from 0 to 23. Together the cases cover every hour of the day once.
public enum WMFYearInReviewTimeOfDay: String, Codable, Sendable, CaseIterable {
    /// 5:00 AM to 11:59 AM.
    case mornings
    /// 12:00 PM to 12:59 PM.
    case middays
    /// 1:00 PM to 4:59 PM.
    case afternoons
    /// 5:00 PM to 8:59 PM.
    case evenings
    /// 9:00 PM to 11:59 PM.
    case nights
    /// 12:00 AM to 4:59 AM.
    case lateNights

    /// The hours of the day in this part of the day, from 0 to 23.
    public var hours: Range<Int> {
        switch self {
        case .mornings: 5..<12
        case .middays: 12..<13
        case .afternoons: 13..<17
        case .evenings: 17..<21
        case .nights: 21..<24
        case .lateNights: 0..<5
        }
    }

    /// The part of the day that `hour` is in. `nil` if `hour` is not from 0 to 23.
    public init?(hour: Int) {
        guard let timeOfDay = Self.allCases.first(where: { $0.hours.contains(hour) }) else {
            return nil
        }
        self = timeOfDay
    }
}
