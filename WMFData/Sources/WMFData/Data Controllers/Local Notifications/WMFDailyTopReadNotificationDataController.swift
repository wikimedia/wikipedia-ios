import Foundation

/// Schedules a once-daily local notification featuring today's top most-read article. Intended to be driven only from background app refresh.
public actor WMFDailyTopReadNotificationDataController {

    public static let shared = WMFDailyTopReadNotificationDataController()

    private static let type = WMFLocalNotificationType.dailyTopRead
    static let fireHour = 10
    static let cutoffHour = 21
    static let immediateFireDelay: TimeInterval = 5

    private let feedDataController: WMFFeedDataControlling
    private let localNotificationDataController: WMFLocalNotificationDataController
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let isEnabled: @Sendable () -> Bool

    public init(feedDataController: WMFFeedDataControlling = WMFFeedDataController.shared,
                localNotificationDataController: WMFLocalNotificationDataController = .shared,
                calendar: Calendar = .current,
                now: @escaping @Sendable () -> Date = { Date() },
                isEnabled: @escaping @Sendable () -> Bool = { WMFDeveloperSettingsDataController.enableDailyTopReadNotifications }) {
        self.feedDataController = feedDataController
        self.localNotificationDataController = localNotificationDataController
        self.calendar = calendar
        self.now = now
        self.isEnabled = isEnabled
    }

    public static func identifier(forDay day: String) -> String {
        "\(type.rawValue)-\(day)"
    }

    // MARK: - Public

    /// Fetches today's top read article and schedules a notification for it, unless one was already handled today.
    /// - Parameters:
    ///   - project: Wikipedia project to fetch the featured feed from.
    ///   - bodyFormat: Localized format string, where %1$@ is replaced by the article title.
    ///   - appState: Application state description, recorded in the log.
    public func scheduleIfNeeded(project: WMFProject, bodyFormat: String, appState: String?) async {
        guard isEnabled() else { return }

        let date = now()
        let day = WMFLocalNotificationDataController.dayString(for: date, calendar: calendar)
        let authorizationStatus = await localNotificationDataController.authorizationStatus()

        await log(.attempt, appState: appState, authorizationStatus: authorizationStatus)

        guard await !localNotificationDataController.isHandled(type: Self.type, day: day) else {
            await log(.skippedAlreadyHandled, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        guard authorizationStatus.isAuthorized else {
            await log(.skippedNotAuthorized, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        guard let fireDate = fireDate(for: date) else {
            await log(.skippedTooLate, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        let articleTitle: String
        do {
            let response = try await feedDataController.fetchFeed(project: project, date: date)
            guard let title = Self.topArticleTitle(from: response) else {
                await log(.failedNoContent, appState: appState, authorizationStatus: authorizationStatus)
                return
            }
            articleTitle = title
        } catch {
            await log(.failedFetch, appState: appState, authorizationStatus: authorizationStatus, error: String(describing: error))
            return
        }

        let notification = WMFLocalNotification(
            type: Self.type,
            identifier: Self.identifier(forDay: day),
            body: String.localizedStringWithFormat(bodyFormat, articleTitle),
            fireDate: fireDate)

        do {
            try await localNotificationDataController.schedule(notification)
            await localNotificationDataController.markHandled(type: Self.type, day: day)
            await log(.scheduled, appState: appState, authorizationStatus: authorizationStatus, contentSummary: articleTitle, fireDate: fireDate)
        } catch {
            await log(.failedSchedule, appState: appState, authorizationStatus: authorizationStatus, contentSummary: articleTitle, fireDate: fireDate, error: String(describing: error))
        }
    }

    /// Call when the user views today's Top Read list on their own. Cancels today's notification and prevents one from being scheduled later today.
    public func userDidViewTopRead(appState: String?) async {
        guard isEnabled() else { return }

        let day = WMFLocalNotificationDataController.dayString(for: now(), calendar: calendar)
        let wasPending = await localNotificationDataController.cancel(identifier: Self.identifier(forDay: day))
        await localNotificationDataController.markHandled(type: Self.type, day: day)
        if wasPending {
            await log(.cancelledByUserVisit, appState: appState)
        }
    }

    /// Call when the feature flag is turned off. Cancels any notification that is still waiting to fire.
    public func userDidDisable() async {
        let cancelled = await localNotificationDataController.cancelAll(type: Self.type)
        if !cancelled.isEmpty {
            await log(.cancelledByDisable, appState: nil)
        }
    }

    public func logTap(appState: String?) async {
        await log(.tapped, appState: appState)
    }

    // MARK: - Private

    /// Before 10 AM: fire at 10 AM. Before 9 PM: fire shortly. Otherwise nil (too late to notify today).
    func fireDate(for date: Date) -> Date? {
        guard let fireTime = calendar.date(bySettingHour: Self.fireHour, minute: 0, second: 0, of: date),
              let cutoffTime = calendar.date(bySettingHour: Self.cutoffHour, minute: 0, second: 0, of: date) else {
            return nil
        }

        if date < fireTime {
            return fireTime
        } else if date < cutoffTime {
            return date.addingTimeInterval(Self.immediateFireDelay)
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

    private func log(_ event: WMFLocalNotificationLogEntry.Event, appState: String?, authorizationStatus: WMFLocalNotificationAuthorizationStatus? = nil, contentSummary: String? = nil, fireDate: Date? = nil, error: String? = nil) async {
        let entry = WMFLocalNotificationLogEntry(
            timestamp: now(),
            type: Self.type,
            event: event,
            appState: appState,
            authorizationStatus: authorizationStatus?.rawValue,
            contentSummary: contentSummary,
            fireDate: fireDate,
            error: error)
        await localNotificationDataController.log(entry)
    }
}
