import Foundation
import os

/// One analytics event as the event pipeline saw it, with the result of its submission.
public struct WMFInspectedAnalyticsEvent: Identifiable, Sendable, Equatable {

    public enum Outcome: String, Sendable {
        case recorded
        case droppedNotInSample = "dropped-not-in-sample"
        case droppedUnconfiguredStream = "dropped-unconfigured-stream"

        public var isDropped: Bool {
            self != .recorded
        }
    }

    public let id: UUID
    public let date: Date
    public let stream: String
    public let outcome: Outcome
    public let payload: Data

    /// The `action` field of the payload. Every app event has one.
    public let action: String?
    /// The `active_interface` field of the payload, when the schema has one.
    public let activeInterface: String?
    /// The `$schema` field of the payload.
    public let schema: String?

    public init(id: UUID = UUID(), date: Date = Date(), stream: String, outcome: Outcome, payload: Data) {
        self.id = id
        self.date = date
        self.stream = stream
        self.outcome = outcome
        self.payload = payload

        let json = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any]
        self.action = json?["action"] as? String
        self.activeInterface = json?["active_interface"] as? String
        self.schema = json?["$schema"] as? String
    }

    /// The payload as indented JSON with sorted keys. Returns the raw text when the payload is not JSON.
    public func prettyPrintedPayload() -> String {
        guard let object = try? JSONSerialization.jsonObject(with: payload),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let text = String(bytes: data, encoding: .utf8) else {
            return String(bytes: payload, encoding: .utf8) ?? ""
        }
        return text
    }
}

/// Keeps the most recent analytics events in memory for the Analytics Inspector in developer settings.
/// The event pipeline calls `record` synchronously from its own GCD queues, so a lock guards the buffer
/// instead of an actor: a hop would delay event submission. Nothing is persisted, and nothing is kept
/// while the developer setting is off, so the buffer holds the session: every event since the app
/// opened or since the setting went on, whichever is later. The capacity only protects memory.
public final class WMFAnalyticsEventInspectorDataController: Sendable {

    public static let shared = WMFAnalyticsEventInspectorDataController()
    public static let defaultCapacity = 5000

    private struct State: Sendable {
        var events: [WMFInspectedAnalyticsEvent] = []
        var continuations: [UUID: AsyncStream<WMFInspectedAnalyticsEvent>.Continuation] = [:]
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let capacity: Int
    private let isEnabledProvider: @Sendable () -> Bool

    /// The default provider reads the developer setting. Tests inject their own.
    public init(capacity: Int = WMFAnalyticsEventInspectorDataController.defaultCapacity, isEnabled: @escaping @Sendable () -> Bool = { WMFDeveloperSettingsDataController.shared.showAnalyticsInspector }) {
        self.capacity = capacity
        self.isEnabledProvider = isEnabled
    }

    /// True while the developer setting is on.
    public var isEnabled: Bool {
        isEnabledProvider()
    }

    /// Stores one event and delivers it to every open `eventStream()`. Does nothing while the setting is off.
    public func record(payload: Data, stream: String, outcome: WMFInspectedAnalyticsEvent.Outcome) {
        guard isEnabled else {
            return
        }

        let event = WMFInspectedAnalyticsEvent(stream: stream, outcome: outcome, payload: payload)
        let continuations = state.withLock { state in
            state.events.append(event)
            let overflow = state.events.count - capacity
            if overflow > 0 {
                state.events.removeFirst(overflow)
            }
            return Array(state.continuations.values)
        }

        for continuation in continuations {
            continuation.yield(event)
        }
    }

    /// The stored events, oldest first.
    public func events() -> [WMFInspectedAnalyticsEvent] {
        state.withLock { $0.events }
    }

    public func clear() {
        state.withLock { $0.events.removeAll() }
    }

    /// Delivers each event after `record` stores it. The stream ends when the consuming task is cancelled.
    public func eventStream() -> AsyncStream<WMFInspectedAnalyticsEvent> {
        let id = UUID()
        let state = self.state
        return AsyncStream { continuation in
            state.withLock { $0.continuations[id] = continuation }
            continuation.onTermination = { _ in
                state.withLock { _ = $0.continuations.removeValue(forKey: id) }
            }
        }
    }
}
