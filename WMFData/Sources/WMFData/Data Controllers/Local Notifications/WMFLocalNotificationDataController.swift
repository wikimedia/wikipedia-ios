import Foundation

/// Feature-agnostic layer for scheduling local notifications, tracking which days a notification type has been handled, and persisting a lifecycle log.
/// Daily notification features call `scheduleDaily` and provide only their fire time rules and content.
public actor WMFLocalNotificationDataController {

    public static let shared = WMFLocalNotificationDataController()

    static let maxLogEntries = 2000
    private static let logFileName = "log"

    private let scheduler: WMFLocalNotificationScheduling
    private let injectedUserDefaultsStore: WMFKeyValueStore?
    private let injectedSharedCacheStore: WMFKeyValueStore?
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    private var userDefaultsStore: WMFKeyValueStore? {
        injectedUserDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
    }

    private var sharedCacheStore: WMFKeyValueStore? {
        injectedSharedCacheStore ?? WMFDataEnvironment.current.sharedCacheStore
    }

    public init(scheduler: WMFLocalNotificationScheduling = WMFUserNotificationCenterScheduler(),
                userDefaultsStore: WMFKeyValueStore? = nil,
                sharedCacheStore: WMFKeyValueStore? = nil,
                calendar: Calendar = .current,
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.scheduler = scheduler
        self.injectedUserDefaultsStore = userDefaultsStore
        self.injectedSharedCacheStore = sharedCacheStore
        self.calendar = calendar
        self.now = now
    }

    // MARK: - Daily notifications

    /// Identifier of the daily notification of this type for a day string (yyyy-MM-dd).
    public static func dailyIdentifier(type: WMFLocalNotificationType, day: String) -> String {
        "\(type.rawValue)-\(day)"
    }

    /// Schedules today's notification of this type, unless one was already handled today. Each step is logged.
    /// - Parameters:
    ///   - type: The daily notification type. Callers check their own feature flag before calling.
    ///   - appState: Application state description, recorded in the log.
    ///   - fireDate: When to fire, given the current date and calendar. Nil skips today as too late.
    ///   - content: Fetches the notification content for the current date. Nil logs `failedNoContent`; throwing logs `failedFetch`.
    public func scheduleDaily(type: WMFLocalNotificationType,
                              appState: String?,
                              fireDate: @Sendable (_ now: Date, _ calendar: Calendar) -> Date?,
                              content: @Sendable (_ now: Date) async throws -> WMFLocalNotificationContent?) async {
        let date = now()
        let day = Self.dayString(for: date, calendar: calendar)
        let authorizationStatus = await scheduler.authorizationStatus()

        log(.attempt, type: type, appState: appState, authorizationStatus: authorizationStatus)

        guard !isHandled(type: type, day: day) else {
            log(.skippedAlreadyHandled, type: type, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        guard authorizationStatus.isAuthorized else {
            log(.skippedNotAuthorized, type: type, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        guard let fireDate = fireDate(date, calendar) else {
            log(.skippedTooLate, type: type, appState: appState, authorizationStatus: authorizationStatus)
            return
        }

        let notificationContent: WMFLocalNotificationContent
        do {
            guard let fetchedContent = try await content(date) else {
                log(.failedNoContent, type: type, appState: appState, authorizationStatus: authorizationStatus)
                return
            }
            notificationContent = fetchedContent
        } catch {
            log(.failedFetch, type: type, appState: appState, authorizationStatus: authorizationStatus, error: String(describing: error))
            return
        }

        let notification = WMFLocalNotification(
            type: type,
            identifier: Self.dailyIdentifier(type: type, day: day),
            title: notificationContent.title,
            body: notificationContent.body,
            fireDate: fireDate)

        do {
            try await scheduler.add(notification)
            markHandled(type: type, day: day)
            log(.scheduled, type: type, appState: appState, authorizationStatus: authorizationStatus, contentSummary: notificationContent.logSummary, fireDate: fireDate)
        } catch {
            log(.failedSchedule, type: type, appState: appState, authorizationStatus: authorizationStatus, contentSummary: notificationContent.logSummary, fireDate: fireDate, error: String(describing: error))
        }
    }

    /// Call when the user has seen the content on their own. Cancels today's pending notification of this type
    /// and prevents one from being scheduled later today. Logs `cancelledByUserVisit` if one was pending.
    public func suppressDailyForToday(type: WMFLocalNotificationType, appState: String?) async {
        let day = Self.dayString(for: now(), calendar: calendar)
        let wasPending = await cancel(identifier: Self.dailyIdentifier(type: type, day: day))
        markHandled(type: type, day: day)
        if wasPending {
            log(.cancelledByUserVisit, type: type, appState: appState)
        }
    }

    // MARK: - Scheduling

    public func authorizationStatus() async -> WMFLocalNotificationAuthorizationStatus {
        await scheduler.authorizationStatus()
    }

    public func schedule(_ notification: WMFLocalNotification) async throws {
        try await scheduler.add(notification)
    }

    /// Removes pending and delivered notifications with this identifier. Returns true if a matching notification was still pending.
    @discardableResult
    public func cancel(identifier: String) async -> Bool {
        let wasPending = await scheduler.pendingIdentifiers().contains(identifier)
        await scheduler.remove(identifiers: [identifier])
        return wasPending
    }

    /// Removes every pending and delivered notification of this type. Returns the identifiers that were still pending.
    @discardableResult
    public func cancelAll(type: WMFLocalNotificationType) async -> [String] {
        let identifiers = await scheduler.pendingIdentifiers(type: type)
        if !identifiers.isEmpty {
            await scheduler.remove(identifiers: identifiers)
        }
        return identifiers
    }

    // MARK: - Handled days

    /// Whether a notification of this type has already been scheduled (or intentionally suppressed) for the day string (yyyy-MM-dd).
    public func isHandled(type: WMFLocalNotificationType, day: String) -> Bool {
        handledDays()[type.rawValue] == day
    }

    public func markHandled(type: WMFLocalNotificationType, day: String) {
        var days = handledDays()
        days[type.rawValue] = day
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.localNotificationsHandledDays.rawValue, value: days)
    }

    /// Forgets every handled day, so each notification type can be scheduled again today. For developer testing.
    public func resetHandledDays() {
        try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.localNotificationsHandledDays.rawValue)
    }

    private func handledDays() -> [String: String] {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.localNotificationsHandledDays.rawValue)) ?? [:]
    }

    // MARK: - Log

    /// Logs an event with the current time.
    public func log(_ event: WMFLocalNotificationLogEntry.Event, type: WMFLocalNotificationType, appState: String?, authorizationStatus: WMFLocalNotificationAuthorizationStatus? = nil, contentSummary: String? = nil, fireDate: Date? = nil, error: String? = nil) {
        log(WMFLocalNotificationLogEntry(
            timestamp: now(),
            type: type,
            event: event,
            appState: appState,
            authorizationStatus: authorizationStatus?.rawValue,
            contentSummary: contentSummary,
            fireDate: fireDate,
            error: error))
    }

    public func log(_ entry: WMFLocalNotificationLogEntry) {
        var entries = loadLog()
        entries.append(entry)
        if entries.count > Self.maxLogEntries {
            entries.removeFirst(entries.count - Self.maxLogEntries)
        }
        try? sharedCacheStore?.save(key: WMFSharedCacheDirectoryNames.localNotifications.rawValue, Self.logFileName, value: entries)
    }

    public func loadLog() -> [WMFLocalNotificationLogEntry] {
        (try? sharedCacheStore?.load(key: WMFSharedCacheDirectoryNames.localNotifications.rawValue, Self.logFileName)) ?? []
    }

    public func clearLog() {
        try? sharedCacheStore?.remove(key: WMFSharedCacheDirectoryNames.localNotifications.rawValue, Self.logFileName)
    }

    /// The full log as pretty-printed JSON, for exporting off device.
    public func exportLogData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(loadLog())
    }

    // MARK: - Helpers

    /// yyyy-MM-dd string for the date in the given calendar's time zone.
    public static func dayString(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
