import Testing
import Foundation
import WMFData
@testable import WMFComponents

@MainActor
@Suite
struct WMFAnalyticsInspectorViewModelTests {

    private func makeEvent(action: String? = nil, activeInterface: String? = nil, stream: String = "ios.saved", outcome: WMFInspectedAnalyticsEvent.Outcome = .recorded, schema: String? = "/analytics/mobile_apps/ios_reading_lists/2.2.0", date: Date = Date(timeIntervalSince1970: 0)) -> WMFInspectedAnalyticsEvent {
        var json: [String: Any] = [:]
        if let action {
            json["action"] = action
        }
        if let activeInterface {
            json["active_interface"] = activeInterface
        }
        if let schema {
            json["$schema"] = schema
        }
        let payload = try! JSONSerialization.data(withJSONObject: json)
        return WMFInspectedAnalyticsEvent(date: date, stream: stream, outcome: outcome, payload: payload)
    }

    private func makeViewModel(capacity: Int = WMFAnalyticsEventInspectorDataController.defaultCapacity) -> WMFAnalyticsInspectorViewModel {
        WMFAnalyticsInspectorViewModel(dataController: WMFAnalyticsEventInspectorDataController(isEnabled: { true }), capacity: capacity)
    }

    @Test
    func appendKeepsNewestFirstAndUpdatesTheLatestEvent() {
        let viewModel = makeViewModel()
        let first = makeEvent(action: "first")
        let second = makeEvent(action: "second")

        viewModel.append(first)
        viewModel.append(second)

        #expect(viewModel.events.map(\.action) == ["second", "first"])
        #expect(viewModel.latestEvent?.id == second.id)
    }

    @Test
    func appendRespectsTheCapacity() {
        let viewModel = makeViewModel(capacity: 2)

        for index in 0..<4 {
            viewModel.append(makeEvent(action: "action-\(index)"))
        }

        #expect(viewModel.events.map(\.action) == ["action-3", "action-2"])
    }

    @Test
    func initLoadsTheEventsTheDataControllerAlreadyHolds() {
        let dataController = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        dataController.record(payload: Data(#"{"action":"old"}"#.utf8), stream: "ios.saved", outcome: .recorded)
        dataController.record(payload: Data(#"{"action":"new"}"#.utf8), stream: "ios.saved", outcome: .recorded)

        let viewModel = WMFAnalyticsInspectorViewModel(dataController: dataController)

        #expect(viewModel.events.map(\.action) == ["new", "old"])
        #expect(viewModel.latestEvent?.action == "new")
    }

    @Test
    func startDeliversEventsTheDataControllerRecords() async {
        let dataController = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        let viewModel = WMFAnalyticsInspectorViewModel(dataController: dataController)
        viewModel.start()
        defer { viewModel.stop() }

        dataController.record(payload: Data(#"{"action":"live"}"#.utf8), stream: "ios.saved", outcome: .recorded)

        for await _ in viewModel.$latestEvent.values where viewModel.latestEvent != nil {
            break
        }
        #expect(viewModel.latestEvent?.action == "live")
    }

    @Test
    func titleFallsBackFromActionToSchemaToStream() {
        let viewModel = makeViewModel()

        #expect(viewModel.title(for: makeEvent(action: "impression")) == "impression")
        #expect(viewModel.title(for: makeEvent(action: nil)) == "ios_reading_lists")
        #expect(viewModel.title(for: makeEvent(action: nil, stream: "ios.other", schema: nil)) == "ios.other")
    }

    @Test
    func subtitleJoinsStreamAndInterface() {
        let viewModel = makeViewModel()

        #expect(viewModel.subtitle(for: makeEvent(activeInterface: "saved")) == "ios.saved · saved")
        #expect(viewModel.subtitle(for: makeEvent()) == "ios.saved")
    }

    @Test
    func pillTextWaitsWithoutAnEvent() {
        let viewModel = makeViewModel()

        #expect(viewModel.pillText(for: nil) == viewModel.localizedStrings.waiting)
        #expect(viewModel.pillText(for: makeEvent(action: "impression")) == "ios.saved · impression")
    }

    @Test
    func filteringByStreamAndSearchText() {
        let viewModel = makeViewModel()
        viewModel.append(makeEvent(action: "impression", activeInterface: "saved", stream: "ios.saved"))
        viewModel.append(makeEvent(action: "click", activeInterface: "discover", stream: "ios.discover"))
        viewModel.append(makeEvent(action: "impression", activeInterface: "discover", stream: "ios.discover"))

        #expect(viewModel.availableStreams == ["ios.discover", "ios.saved"])
        #expect(viewModel.filteredEvents.count == 3)

        viewModel.streamFilter = "ios.discover"
        #expect(viewModel.filteredEvents.count == 2)

        viewModel.searchText = "IMPRESS"
        #expect(viewModel.filteredEvents.map(\.action) == ["impression"])

        viewModel.streamFilter = nil
        #expect(viewModel.filteredEvents.map(\.action) == ["impression", "impression"])
    }

    @Test
    func outcomeTextNamesTheDrop() {
        let viewModel = makeViewModel()

        #expect(viewModel.outcomeText(for: makeEvent(outcome: .recorded)) == viewModel.localizedStrings.recorded)
        #expect(viewModel.outcomeText(for: makeEvent(outcome: .droppedNotInSample)) == viewModel.localizedStrings.droppedNotInSample)
        #expect(viewModel.outcomeText(for: makeEvent(outcome: .droppedUnconfiguredStream)) == viewModel.localizedStrings.droppedUnconfiguredStream)
    }

    @Test
    func sessionExportListsEveryEventOldestFirstWithAHeader() {
        let viewModel = makeViewModel()
        viewModel.append(makeEvent(action: "first", date: Date(timeIntervalSince1970: 0)))
        viewModel.append(makeEvent(action: "second", date: Date(timeIntervalSince1970: 60)))
        viewModel.streamFilter = "ios.other"

        let export = viewModel.sessionExportText()

        #expect(export.hasPrefix("Analytics Inspector export: 2 events, "))
        let firstRange = export.range(of: "\"action\" : \"first\"")
        let secondRange = export.range(of: "\"action\" : \"second\"")
        #expect(firstRange != nil && secondRange != nil)
        if let firstRange, let secondRange {
            #expect(firstRange.lowerBound < secondRange.lowerBound)
        }
        #expect(export.contains("ios.saved [Recorded]"))
    }

    @Test
    func clearEmptiesTheViewModelAndTheDataController() {
        let dataController = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        dataController.record(payload: Data(#"{"action":"old"}"#.utf8), stream: "ios.saved", outcome: .recorded)
        let viewModel = WMFAnalyticsInspectorViewModel(dataController: dataController)

        viewModel.clear()

        #expect(viewModel.events.isEmpty)
        #expect(viewModel.latestEvent == nil)
        #expect(dataController.events().isEmpty)
    }
}
