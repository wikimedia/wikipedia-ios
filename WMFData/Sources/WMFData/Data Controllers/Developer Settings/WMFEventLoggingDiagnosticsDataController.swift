import Foundation
import os

/// Counters describing the event-logging pipeline's request and drop behavior,
/// surfaced in developer settings so intake traffic is measurable.
public struct WMFEventLoggingDiagnostics: Codable, Sendable {
    public var flushCount: Int = 0
    public var postCount: Int = 0
    public var eventsSentCount: Int = 0
    public var eventsInLastFlush: Int = 0
    public var dropCounts: [String: Int] = [:]
    public var lastFlushDate: Date?

    public init() {
    }
}

public enum WMFEventDropReason: String, Sendable {
    case serverRejected = "server-rejected"
    case errorThrottled = "error-throttled"
    case notInSample = "not-in-sample"
    case unconfiguredStream = "unconfigured-stream"
    case inputBufferOverflow = "input-buffer-overflow"
}

/// Records and reads the event-logging diagnostics counters. Increments arrive from
/// GCD callbacks and background threads in the event pipeline, so the read-modify-write
/// is guarded by a lock rather than an actor — every call site is synchronous, and a
/// counter must never make the pipeline hop or wait. Failures to persist are swallowed:
/// diagnostics must never affect event sending.
public final class WMFEventLoggingDiagnosticsDataController: Sendable {

    public static let shared = WMFEventLoggingDiagnosticsDataController()

    private let lock = OSAllocatedUnfairLock()

    private var userDefaultsStore: WMFKeyValueStore? {
        WMFDataEnvironment.current.userDefaultsStore
    }

    public func recordFlush(posts: Int, events: Int) {
        mutate { diagnostics in
            diagnostics.flushCount += 1
            diagnostics.postCount += posts
            diagnostics.eventsSentCount += events
            diagnostics.eventsInLastFlush = events
            diagnostics.lastFlushDate = Date()
        }
    }

    public func recordDrop(reason: WMFEventDropReason, count: Int = 1) {
        mutate { diagnostics in
            diagnostics.dropCounts[reason.rawValue, default: 0] += count
        }
    }

    public func snapshot() -> WMFEventLoggingDiagnostics {
        return lock.withLock {
            return load()
        }
    }

    public func reset() {
        lock.withLock {
            try? userDefaultsStore?.remove(key: WMFUserDefaultsKey.eventLoggingDiagnostics.rawValue)
        }
    }

    private func load() -> WMFEventLoggingDiagnostics {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.eventLoggingDiagnostics.rawValue)) ?? WMFEventLoggingDiagnostics()
    }

    private func mutate(_ block: (inout WMFEventLoggingDiagnostics) -> Void) {
        lock.withLock {
            var diagnostics = load()
            block(&diagnostics)
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.eventLoggingDiagnostics.rawValue, value: diagnostics)
        }
    }
}
