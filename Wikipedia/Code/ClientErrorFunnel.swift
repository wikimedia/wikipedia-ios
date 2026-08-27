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

// @unchecked because NSObject is not Sendable; the only mutable state is the
// throttle, which is guarded by its lock, and EventPlatformClient.submit handles
// its own synchronization — so it is safe to use from any thread.
@objc(WMFClientErrorFunnel) public final class ClientErrorFunnel: NSObject, @unchecked Sendable {

    @objc public static let shared = ClientErrorFunnel()

    private let throttle = OSAllocatedUnfairLock(initialState: ClientErrorThrottle())

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .clientError
        let message: String?
        let errorClass: String?
        let errorContext: String?
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
            errorContext: nil,
            stackTrace: nil,
            url: nil,
            http: nil
        )

        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
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
            return
        }

        let http = Event.Http(method: info.method, statusCode: info.statusCode)
        let event = Event(
            message: "HTTP \(info.statusCode)",
            errorClass: info.source,
            errorContext: nil,
            stackTrace: nil,
            url: info.url,
            http: http
        )
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }
}
