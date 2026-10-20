import Foundation

/// Schedules a once-daily local notification featuring today's top most-read article. Intended to be driven only from background app refresh.
/// Provides the fire time rules and content; `WMFLocalNotificationDataController.scheduleDaily` runs the shared scheduling pipeline.
public actor WMFDailyTopReadNotificationDataController {

    public static let shared = WMFDailyTopReadNotificationDataController()

    private static let type = WMFLocalNotificationType.dailyTopRead
    static let fireHour = 10
    static let cutoffHour = 21
    static let immediateFireDelay: TimeInterval = 5

    private let feedDataController: WMFFeedDataControlling
    private let localNotificationDataController: WMFLocalNotificationDataController
    private let isEnabled: @Sendable () -> Bool

    public init(feedDataController: WMFFeedDataControlling = WMFFeedDataController.shared,
                localNotificationDataController: WMFLocalNotificationDataController = .shared,
                isEnabled: @escaping @Sendable () -> Bool = { WMFDeveloperSettingsDataController.enableDailyTopReadNotifications }) {
        self.feedDataController = feedDataController
        self.localNotificationDataController = localNotificationDataController
        self.isEnabled = isEnabled
    }

    // MARK: - Public

    /// Fetches today's top read article and schedules a notification for it, unless one was already handled today.
    /// - Parameters:
    ///   - project: Wikipedia project to fetch the featured feed from.
    ///   - bodyFormat: Localized format string, where %1$@ is replaced by the article title.
    ///   - appState: Application state description, recorded in the log.
    public func scheduleIfNeeded(project: WMFProject, bodyFormat: String, appState: String?) async {
        guard isEnabled() else { return }

        let feedDataController = self.feedDataController
        await localNotificationDataController.scheduleDaily(
            type: Self.type,
            appState: appState,
            fireDate: { now, calendar in
                Self.fireDate(for: now, calendar: calendar)
            },
            content: { now in
                let response = try await feedDataController.fetchFeed(project: project, date: now)
                guard let articleTitle = Self.topArticleTitle(from: response) else {
                    return nil
                }
                return WMFLocalNotificationContent(body: String.localizedStringWithFormat(bodyFormat, articleTitle), logSummary: articleTitle)
            })
    }

    /// Call when the user views today's Top Read list on their own. Cancels today's notification and prevents one from being scheduled later today.
    public func userDidViewTopRead(appState: String?) async {
        guard isEnabled() else { return }

        await localNotificationDataController.suppressDailyForToday(type: Self.type, appState: appState)
    }

    /// Call when the feature flag is turned off. Cancels any notification that is still waiting to fire.
    public func userDidDisable() async {
        let cancelled = await localNotificationDataController.cancelAll(type: Self.type)
        if !cancelled.isEmpty {
            await localNotificationDataController.log(.cancelledByDisable, type: Self.type, appState: nil)
        }
    }

    public func logTap(appState: String?) async {
        await localNotificationDataController.log(.tapped, type: Self.type, appState: appState)
    }

    // MARK: - Private

    /// Before 10 AM: fire at 10 AM. Before 9 PM: fire shortly. Otherwise nil (too late to notify today).
    static func fireDate(for date: Date, calendar: Calendar) -> Date? {
        guard let fireTime = calendar.date(bySettingHour: fireHour, minute: 0, second: 0, of: date),
              let cutoffTime = calendar.date(bySettingHour: cutoffHour, minute: 0, second: 0, of: date) else {
            return nil
        }

        if date < fireTime {
            return fireTime
        } else if date < cutoffTime {
            return date.addingTimeInterval(immediateFireDelay)
        }
        return nil
    }

    static func topArticleTitle(from response: WMFFeedAPIResponse) -> String? {
        guard let articles = response.mostRead?.articles, !articles.isEmpty else {
            return nil
        }

        let topArticle = articles.min { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) } ?? articles[0]
        let title = topArticle.titles?.normalized ?? topArticle.normalizedTitle ?? topArticle.title
        return title?.replacingOccurrences(of: "_", with: " ")
    }
}
