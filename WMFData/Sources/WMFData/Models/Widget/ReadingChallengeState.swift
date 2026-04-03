import Foundation

public enum ReadingChallengeState: Equatable {
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
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 1).date
            ?? Date(timeIntervalSince1970: 1777593600)
    }
    public static var endDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 31, hour: 23, minute: 59, second: 59).date
            ?? Date(timeIntervalSince1970: 1780271999)
    }
    public static var removeDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 7, day: 10).date
            ?? Date(timeIntervalSince1970: 1783987200)
    }
    public static let streakGoal = 25
}
