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
        if WMFDeveloperSettingsDataController.shared.readingChallengeDatesRelativeToToday {
            return Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        }
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 1).date
            ?? Date(timeIntervalSince1970: 1746057600)
    }
    public static var endDate: Date {
        if WMFDeveloperSettingsDataController.shared.readingChallengeDatesRelativeToToday {
            return Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()
        }
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 31).date
            ?? Date(timeIntervalSince1970: 1748649600)
    }
    public static var removeDate: Date {
        if WMFDeveloperSettingsDataController.shared.readingChallengeDatesRelativeToToday {
            return Calendar.current.date(byAdding: .day, value: 50, to: Date()) ?? Date()
        }
        return DateComponents(calendar: .current, year: 2026, month: 7, day: 10).date
            ?? Date(timeIntervalSince1970: 1752105600)
    }
    public static let streakGoal = 25
}
