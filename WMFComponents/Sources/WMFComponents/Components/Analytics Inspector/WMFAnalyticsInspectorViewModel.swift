import Foundation
import UIKit
import WMFData

/// Drives the Analytics Inspector pill and its event list. One instance serves both, so the list
/// shows the same events the pill announced.
@MainActor
public final class WMFAnalyticsInspectorViewModel: ObservableObject {

    /// Newest first.
    @Published public private(set) var events: [WMFInspectedAnalyticsEvent] = []
    @Published public private(set) var latestEvent: WMFInspectedAnalyticsEvent?
    @Published public var streamFilter: String?
    @Published public var searchText: String = ""

    /// Set by the app. Called when the pill is tapped.
    public var didTapPill: (@MainActor () -> Void)?

    let localizedStrings = LocalizedStrings()

    private let dataController: WMFAnalyticsEventInspectorDataController
    private let capacity: Int
    private var streamTask: Task<Void, Never>?

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    public init(dataController: WMFAnalyticsEventInspectorDataController = .shared, capacity: Int = WMFAnalyticsEventInspectorDataController.defaultCapacity) {
        self.dataController = dataController
        self.capacity = capacity
        self.events = dataController.events().reversed()
        self.latestEvent = events.first
    }

    deinit {
        streamTask?.cancel()
    }

    // MARK: - Live updates

    public func start() {
        streamTask?.cancel()
        let stream = dataController.eventStream()
        streamTask = Task { [weak self] in
            for await event in stream {
                guard let self else {
                    return
                }
                self.append(event)
            }
        }
    }

    public func stop() {
        streamTask?.cancel()
        streamTask = nil
    }

    func append(_ event: WMFInspectedAnalyticsEvent) {
        events.insert(event, at: 0)
        if events.count > capacity {
            events.removeLast(events.count - capacity)
        }
        latestEvent = event
    }

    public func clear() {
        dataController.clear()
        events = []
        latestEvent = nil
    }

    // MARK: - Filtering

    public var availableStreams: [String] {
        Set(events.map(\.stream)).sorted()
    }

    public var filteredEvents: [WMFInspectedAnalyticsEvent] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return events.filter { event in
            if let streamFilter, event.stream != streamFilter {
                return false
            }
            guard !query.isEmpty else {
                return true
            }
            let haystack = [title(for: event), event.activeInterface ?? "", event.stream]
            return haystack.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    // MARK: - Display

    /// The action, or the schema name when the event has no action.
    public func title(for event: WMFInspectedAnalyticsEvent) -> String {
        if let action = event.action, !action.isEmpty {
            return action
        }
        if let schemaName = schemaName(of: event.schema) {
            return schemaName
        }
        return event.stream
    }

    public func subtitle(for event: WMFInspectedAnalyticsEvent) -> String {
        [event.stream, event.activeInterface].compactMap { $0 }.joined(separator: " · ")
    }

    public func pillText(for event: WMFInspectedAnalyticsEvent?) -> String {
        guard let event else {
            return localizedStrings.waiting
        }
        return "\(event.stream) · \(title(for: event))"
    }

    public func outcomeText(for event: WMFInspectedAnalyticsEvent) -> String {
        switch event.outcome {
        case .recorded:
            return localizedStrings.recorded
        case .droppedNotInSample:
            return localizedStrings.droppedNotInSample
        case .droppedUnconfiguredStream:
            return localizedStrings.droppedUnconfiguredStream
        }
    }

    public func timeText(for event: WMFInspectedAnalyticsEvent) -> String {
        timeFormatter.string(from: event.date)
    }

    /// Plain text with a header and one block per event, oldest first, for sharing the whole session.
    public func sessionExportText() -> String {
        exportText(for: events.reversed())
    }

    /// Plain text with a header and one block per event in the given order, for sharing.
    public func exportText(for events: [WMFInspectedAnalyticsEvent]) -> String {
        let dates = events.map(\.date)
        var header = "Analytics Inspector export: \(events.count) events"
        if let first = dates.min(), let last = dates.max() {
            header += ", \(exportDateFormatter.string(from: first)) to \(exportDateFormatter.string(from: last))"
        }
        let blocks = events.map { event in
            "\(exportDateFormatter.string(from: event.date)) \(event.stream) [\(outcomeText(for: event))]\n\(event.prettyPrintedPayload())"
        }
        return ([header] + blocks).joined(separator: "\n\n")
    }

    public func copyPayload(of event: WMFInspectedAnalyticsEvent) {
        UIPasteboard.general.string = event.prettyPrintedPayload()
    }

    /// "/analytics/mobile_apps/ios_reading_lists/2.2.0" gives "ios_reading_lists".
    private func schemaName(of schema: String?) -> String? {
        guard let schema else {
            return nil
        }
        let components = schema.split(separator: "/").map(String.init)
        guard components.count >= 2 else {
            return components.last
        }
        return components[components.count - 2]
    }

    // MARK: - Strings

    /// Developer-only screen, so the strings stay in English like the rest of developer settings.
    struct LocalizedStrings {
        let title = "Analytics Inspector"
        let waiting = "Analytics Inspector · waiting for events"
        let recorded = "Recorded"
        let droppedNotInSample = "Dropped: not in sample"
        let droppedUnconfiguredStream = "Dropped: stream not configured"
        let searchPlaceholder = "Search action, interface or stream"
        let allStreams = "All streams"
        let streamPicker = "Stream"
        let emptyList = "No events yet. Use the app and come back."
        let copyPayload = "Copy JSON"
        let clear = "Clear events"
        func share(count: Int) -> String { "Share all \(count) events of this session" }
        func header(count: Int) -> String { "\(count) events, newest first" }
    }
}
