import Foundation

/// Feature-agnostic layer for scheduling local notifications, tracking which days a notification type has been handled, and persisting a lifecycle log.
public actor WMFLocalNotificationDataController {

    public static let shared = WMFLocalNotificationDataController()

    static let maxLogEntries = 2000
    private static let logFileName = "log"

    private let scheduler: WMFLocalNotificationScheduling
    private let injectedUserDefaultsStore: WMFKeyValueStore?
    private let injectedSharedCacheStore: WMFKeyValueStore?

    private var userDefaultsStore: WMFKeyValueStore? {
        injectedUserDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
    }

    private var sharedCacheStore: WMFKeyValueStore? {
        injectedSharedCacheStore ?? WMFDataEnvironment.current.sharedCacheStore
    }

    public init(scheduler: WMFLocalNotificationScheduling = WMFUserNotificationCenterScheduler(), userDefaultsStore: WMFKeyValueStore? = nil, sharedCacheStore: WMFKeyValueStore? = nil) {
        self.scheduler = scheduler
        self.injectedUserDefaultsStore = userDefaultsStore
        self.injectedSharedCacheStore = sharedCacheStore
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
