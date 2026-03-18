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
        DateComponents(calendar: .current, year: 2026, month: 5, day: 1).date
            ?? Date(timeIntervalSince1970: 1746057600) // 2026-05-01 UTC fallback
    }
    public static var endDate: Date {
        DateComponents(calendar: .current, year: 2026, month: 5, day: 31).date
            ?? Date(timeIntervalSince1970: 1748649600) // 2026-05-31 UTC fallback
    }
    public static var removeDate: Date {
        DateComponents(calendar: .current, year: 2026, month: 7, day: 10).date
            ?? Date(timeIntervalSince1970: 1752105600) // 2026-07-10 UTC fallback
    }
    public static let streakGoal = 25
}
