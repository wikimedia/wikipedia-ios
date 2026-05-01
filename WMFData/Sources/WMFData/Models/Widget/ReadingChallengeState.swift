import Foundation

public enum ReadingChallengeState: Equatable, Codable, Hashable {
    case challengeRemoved
    case notLiveYet
    case notEnrolled
    case enrolledNotStarted
    case streakOngoingRead(streak: Int)
    case streakOngoingNotYetRead(streak: Int)
    case challengeCompleted
    case challengeConcludedIncomplete(streak: Int)
    case challengeConcludedNoStreak
}

public enum ReadingChallengeStateConfig {
    public static var startDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 4).date
            ?? Date(timeIntervalSince1970: 1777852800)
    }
    public static var endDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 6, day: 18, hour: 23, minute: 59, second: 59).date
            ?? Date(timeIntervalSince1970: 1781827199)
    }
    public static var removeDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 7, day: 27).date
            ?? Date(timeIntervalSince1970: 1785110400)
    }
    public static let streakGoal = 25
}
