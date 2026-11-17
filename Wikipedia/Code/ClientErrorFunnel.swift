import Foundation
import WMF
import WMFData
import os

/// Sliding-window throttle for client-error events, so an outage or a rate-limiting
/// spike can't multiply our own analytics traffic. Pure value type with an injectable
/// clock; all synchronization happens in the funnel's lock.
struct ClientErrorThrottle {
    /// Maximum events per (error class, host, status class) key per window.
    static let maxEventsPerKeyPerWindow = 5
    /// 429s get one event per host per window: a rate-limited host must not receive
    /// an error-event stampede about being rate limited.
    static let maxRateLimitEventsPerHostPerWindow = 1
    static let windowDuration: TimeInterval = 600

    struct Key: Hashable {
        let errorClass: String
        let host: String
        let statusCodeClass: Int
    }

    private struct WindowState {
        var windowStart: Date
        var count: Int
    }

    private var windows: [Key: WindowState] = [:]
    private var rateLimitWindows: [String: WindowState] = [:]

    /// Returns whether an error event with these attributes may be logged, counting it
    /// against its window if so.
    mutating func shouldLog(errorClass: String?, urlString: String?, statusCode: Int?, now: Date = Date()) -> Bool {
        let host = urlString.flatMap { URL(string: $0)?.host } ?? "unknown"
        prune(now: now)

        if statusCode == 429 {
            return Self.admit(&rateLimitWindows, key: host, limit: Self.maxRateLimitEventsPerHostPerWindow, now: now)
        }

        let key = Key(errorClass: errorClass ?? "unknown", host: host, statusCodeClass: (statusCode ?? 0) / 100)
        return Self.admit(&windows, key: key, limit: Self.maxEventsPerKeyPerWindow, now: now)
    }

    private static func admit<K: Hashable>(_ table: inout [K: WindowState], key: K, limit: Int, now: Date) -> Bool {
        if var state = table[key], now.timeIntervalSince(state.windowStart) < Self.windowDuration {
            guard state.count < limit else {
                return false
            }
            state.count += 1
            table[key] = state
            return true
        }
        table[key] = WindowState(windowStart: now, count: 1)
        return true
    }

    /// Bounds memory by dropping expired windows whenever a new event arrives.
    private mutating func prune(now: Date) {
        windows = windows.filter { now.timeIntervalSince($0.value.windowStart) < Self.windowDuration }
        rateLimitWindows = rateLimitWindows.filter { now.timeIntervalSince($0.value.windowStart) < Self.windowDuration }
    }
}

/// Counts the 429s the throttle drops, per host and endpoint family, so the one 429 event
/// that gets through can carry the volume behind it. Pure value type; the funnel's lock
/// does the synchronization.
struct RateLimitSummaryAccumulator {
    struct Summary: Equatable {
        var droppedCount = 0
        var countsByEndpoint: [String: Int] = [:]

        /// "page/mobile-html:40,page/media-list:8" — highest count first, then by name.
        var endpointsValue: String {
            countsByEndpoint
                .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
                .map { "\($0.key):\($0.value)" }
                .joined(separator: ",")
        }
    }

    private var summariesByHost: [String: Summary] = [:]

    mutating func record(urlString: String?) {
        let (host, endpoint) = Self.hostAndEndpoint(from: urlString)
        var summary = summariesByHost[host] ?? Summary()
        summary.droppedCount += 1
        summary.countsByEndpoint[endpoint, default: 0] += 1
        summariesByHost[host] = summary
    }

    mutating func take(host: String) -> Summary? {
        summariesByHost.removeValue(forKey: host)
    }

    mutating func takeAll() -> [String: Summary] {
        defer { summariesByHost = [:] }
        return summariesByHost
    }

    static func hostAndEndpoint(from urlString: String?) -> (host: String, endpoint: String) {
        guard let urlString, let url = URL(string: urlString) else {
            return ("unknown", "unknown")
        }
        return (url.host ?? "unknown", endpointPattern(for: url))
    }

    /// Collapses a URL to its endpoint family. Titles, revisions and dates are dropped.
    static func endpointPattern(for url: URL) -> String {
        let components = url.pathComponents.filter { $0 != "/" }
        if components.contains("api.php") {
            let action = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "action" }?.value ?? "?"
            return "api.php?action=\(action)"
        }
        if let restIndex = components.firstIndex(of: "rest_v1") {
            return components.dropFirst(restIndex + 1).prefix(2).joined(separator: "/")
        }
        if let restIndex = components.firstIndex(of: "rest.php") {
            return "rest.php/" + components.dropFirst(restIndex + 1).prefix(2).joined(separator: "/")
        }
        return components.prefix(2).joined(separator: "/")
    }
}

// @unchecked because NSObject is not Sendable; the only mutable state is the
// throttle, which is guarded by its lock, and EventPlatformClient.submit handles
// its own synchronization — so it is safe to use from any thread.
@objc(WMFClientErrorFunnel) public final class ClientErrorFunnel: NSObject, @unchecked Sendable {

    @objc public static let shared = ClientErrorFunnel()

    private let throttle = OSAllocatedUnfairLock(initialState: ClientErrorThrottle())
    private let rateLimitSummaries = OSAllocatedUnfairLock(initialState: RateLimitSummaryAccumulator())

    // The schema rejects unknown top-level fields (additionalProperties: false),
    // so the app install ID travels inside error_context, the schema's
    // designated field for arbitrary extra data.
    private static var appInstallIDContext: [String: String]? {
        let appInstallID: String? = try? WMFDataEnvironment.current.crossProcessUserDefaultsStore?.load(key: WMFUserDefaultsKey.appInstallID.rawValue)

        guard let appInstallID else {
            return nil
        }

        return ["app_install_id": appInstallID]
    }

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .clientError
        let message: String?
        let errorClass: String?
        let errorContext: [String: String]?
        let stackTrace: String?
        let url: String?
        let http: Http?

        struct Http: Codable {
            let method: String?
            let statusCode: Int

            enum CodingKeys: String, CodingKey {
                case method
                case statusCode = "status_code"
            }
        }

        enum CodingKeys: String, CodingKey {
            case message = "message"
            case errorClass = "error_class"
            case errorContext = "error_context"
            case stackTrace = "stack_trace"
            case url = "url"
            case http = "http"
        }
    }

    func logEvent(message: String?) {
        guard throttle.withLock({ $0.shouldLog(errorClass: "message", urlString: nil, statusCode: nil) }) else {
            WMFEventLoggingDiagnosticsDataController.shared.recordDrop(reason: .errorThrottled)
            return
        }

        let event: ClientErrorFunnel.Event = ClientErrorFunnel.Event(
            message: message,
            errorClass: nil,
            errorContext: Self.appInstallIDContext,
            stackTrace: nil,
            url: nil,
            http: nil
        )

        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }

    /// error_context is the schema's free-form field: app install ID plus what the
    /// server asked (Retry-After) and whether the user saw cached content or the error.
    static func httpErrorContext(for info: WMFHTTPErrorInfo) -> [String: String]? {
        var context = appInstallIDContext ?? [:]
        if let retryAfter = info.retryAfter {
            context["retry_after"] = String(Int(retryAfter))
        }
        if info.servedFromCache {
            context["served_from_cache"] = "true"
        }
        return context.isEmpty ? nil : context
    }

    static func summaryContext(_ summary: RateLimitSummaryAccumulator.Summary) -> [String: String] {
        [
            "dropped_429_count": String(summary.droppedCount),
            "dropped_429_endpoints": summary.endpointsValue
        ]
    }

    public func logHTTPError(info: WMFHTTPErrorInfo) {
        // Never log errors from the event intake itself: that would emit a new event
        // to the same failing endpoint, creating a feedback loop. Intake requests
        // currently bypass the hooks that call this method; this guard makes sure
        // the loop can't be closed by accident later.
        if let url = info.url, url.contains("intake-analytics") || url.contains("intake-logging") {
            return
        }

        guard throttle.withLock({ $0.shouldLog(errorClass: info.source, urlString: info.url, statusCode: info.statusCode) }) else {
            WMFEventLoggingDiagnosticsDataController.shared.recordDrop(reason: .errorThrottled)
            if info.statusCode == 429 {
                rateLimitSummaries.withLock { $0.record(urlString: info.url) }
            }
            return
        }

        var context = Self.httpErrorContext(for: info) ?? [:]
        if info.statusCode == 429 {
            // The event that gets through carries the 429s dropped since the previous one for this host.
            let host = RateLimitSummaryAccumulator.hostAndEndpoint(from: info.url).host
            if let summary = rateLimitSummaries.withLock({ $0.take(host: host) }) {
                context.merge(Self.summaryContext(summary)) { _, new in new }
            }
        }

        let http = Event.Http(method: info.method, statusCode: info.statusCode)
        let event = Event(
            message: "HTTP \(info.statusCode)",
            errorClass: info.source,
            errorContext: context.isEmpty ? nil : context,
            stackTrace: nil,
            url: info.url,
            http: http
        )
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }

    /// Sends the 429s the throttle held back and no later event carried, one event per host.
    /// Call when the app goes to the background, so the last window is not lost.
    public func flushRateLimitSummaries() {
        let summaries = rateLimitSummaries.withLock { $0.takeAll() }
        for (host, summary) in summaries where summary.droppedCount > 0 {
            var context = Self.appInstallIDContext ?? [:]
            context["host"] = host
            context.merge(Self.summaryContext(summary)) { _, new in new }
            let event = Event(
                message: "HTTP 429 summary",
                errorClass: "RateLimitSummary",
                errorContext: context,
                stackTrace: nil,
                url: nil,
                http: nil
            )
            EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
        }
    }
}
