import Foundation
import CoreData

/// Recovers whether a user completed the 2026 Reading Challenge (a 25 day reading streak between
/// May 11, 2026 and June 18, 2026) and persists the result to a durable user defaults flag.
///
/// The Reading Challenge feature was removed from the app in July 2026. While it shipped, the only
/// record of completion was a boolean the Reading Challenge widget extension wrote into the shared
/// app group. That value still exists on device (the removal deleted the key definitions, not the
/// stored values), but it was only ever written by the widget's timeline provider — users who
/// completed the challenge without the widget installed have nothing recorded.
///
/// Recovery therefore combines two signals:
/// 1. The legacy `reading-challenge-user-completed` boolean in the shared app group. Authoritative
///    when present.
/// 2. A recomputation of the longest consecutive-day reading streak inside the challenge window,
///    using locally stored page views. This covers users the widget never flagged.
///
/// Known limitation: page views are the only local record of daily reading, so a user who cleared
/// their reading history will be recovered as not completed unless the legacy widget flag is set.
public actor WMFReadingChallengeCompletionDataController {

    public static let shared = WMFReadingChallengeCompletionDataController()

    // MARK: - Challenge configuration

    /// Restored from the removed `ReadingChallengeStateConfig`.
    private static let streakGoal = 25

    private static var challengeStartDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 11).date
            ?? Date(timeIntervalSince1970: 1778457600)
    }

    private static var challengeEndDate: Date {
        return DateComponents(calendar: .current, year: 2026, month: 6, day: 18, hour: 23, minute: 59, second: 59).date
            ?? Date(timeIntervalSince1970: 1781827199)
    }

    // MARK: - Legacy storage

    /// These keys were removed from `WMFUserDefaultsKey` along with the feature, but the values
    /// themselves were never cleared from the shared app group, so they are still readable.
    private static let legacySharedGroupID = "group.org.wikimedia.wikipedia"
    private static let legacyUserCompletedKey = "reading-challenge-user-completed"

    // MARK: - Properties

    nonisolated(unsafe) private let userDefaultsStore: WMFKeyValueStore?
    nonisolated(unsafe) private let legacyDefaults: UserDefaults?
    private let injectedCoreDataStore: WMFCoreDataStore?

    // MARK: - Lifecycle

    init(userDefaultsStore: WMFKeyValueStore? = nil, legacyDefaults: UserDefaults? = nil, coreDataStore: WMFCoreDataStore? = nil) {
        self.userDefaultsStore = userDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
        self.legacyDefaults = legacyDefaults ?? UserDefaults(suiteName: WMFReadingChallengeCompletionDataController.legacySharedGroupID)
        self.injectedCoreDataStore = coreDataStore
    }

    // MARK: - Public

    /// Whether the user completed the 2026 Reading Challenge. Only meaningful once
    /// `recoverCompletionIfNeeded()` has succeeded, which can be checked via
    /// `didRecoverReadingChallenge2026Completion()`.
    public nonisolated func didCompleteReadingChallenge2026() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.completedReadingChallenge2026.rawValue)) ?? false
    }

    /// Whether recovery has already run to completion. Recovery is a one time operation.
    public nonisolated func didRecoverReadingChallenge2026Completion() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.didRecoverReadingChallenge2026Completion.rawValue)) ?? false
    }

    /// Determines whether the user completed the 2026 Reading Challenge and saves the result to
    /// user defaults. No-ops once recovery has succeeded.
    ///
    /// Throws if page views are unavailable (for example, Core Data is not set up yet) so that the
    /// caller can retry on a later app launch. The recovery flag is only saved on success.
    public func recoverCompletionIfNeeded() async throws {

        guard !didRecoverReadingChallenge2026Completion() else {
            return
        }

        if legacyWidgetRecordedCompletion() {
            save(didComplete: true)
            return
        }

        let longestStreak = try await longestStreakDuringChallenge()
        save(didComplete: longestStreak >= Self.streakGoal)
    }

    // MARK: - Private

    private nonisolated func legacyWidgetRecordedCompletion() -> Bool {
        return legacyDefaults?.bool(forKey: Self.legacyUserCompletedKey) ?? false
    }

    private nonisolated func save(didComplete: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.completedReadingChallenge2026.rawValue, value: didComplete)
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.didRecoverReadingChallenge2026Completion.rawValue, value: true)
    }

    /// Longest run of consecutive calendar days with at least one page view, bounded by the
    /// challenge window. The original feature evaluated the user's *current* streak whenever the
    /// widget refreshed; retroactively, the longest streak within the window is the equivalent of
    /// what the challenge asked for ("complete a 25-day reading streak while the challenge is live").
    private func longestStreakDuringChallenge() async throws -> Int {

        guard let coreDataStore = injectedCoreDataStore ?? WMFDataEnvironment.current.coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Self.challengeStartDate)
        let endDate = Self.challengeEndDate

        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform {

            let fetchRequest: NSFetchRequest<CDPageView> = CDPageView.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as NSDate, endDate as NSDate)
            let pageViews = try backgroundContext.fetch(fetchRequest)

            var daysWithRead = Set<DateComponents>()
            for pageView in pageViews {
                guard let timestamp = pageView.timestamp else { continue }
                daysWithRead.insert(calendar.dateComponents([.year, .month, .day], from: timestamp))
            }

            guard !daysWithRead.isEmpty else {
                return 0
            }

            var longestStreak = 0
            var currentStreak = 0
            var cursor = startDate
            let lastDay = calendar.startOfDay(for: endDate)

            while cursor <= lastDay {
                let components = calendar.dateComponents([.year, .month, .day], from: cursor)
                if daysWithRead.contains(components) {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 0
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = nextDay
            }

            return longestStreak
        }
    }
}
