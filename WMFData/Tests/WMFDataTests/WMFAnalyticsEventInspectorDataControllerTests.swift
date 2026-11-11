import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFAnalyticsEventInspectorDataControllerTests {

    private let fixture = WMFDataTestFixture()

    private func payload(action: String, activeInterface: String? = nil, schema: String? = "/analytics/mobile_apps/ios_test/1.0.0") -> Data {
        var json: [String: Any] = ["action": action]
        if let activeInterface {
            json["active_interface"] = activeInterface
        }
        if let schema {
            json["$schema"] = schema
        }
        return try! JSONSerialization.data(withJSONObject: json)
    }

    @Test
    func recordKeepsEventsOldestFirstAndParsesTheirFields() {
        let controller = WMFAnalyticsEventInspectorDataController(isEnabled: { true })

        controller.record(payload: payload(action: "impression", activeInterface: "saved"), stream: "ios.saved", outcome: .recorded)
        controller.record(payload: payload(action: "click"), stream: "ios.saved", outcome: .droppedNotInSample)

        let events = controller.events()
        #expect(events.count == 2)
        #expect(events[0].action == "impression")
        #expect(events[0].activeInterface == "saved")
        #expect(events[0].schema == "/analytics/mobile_apps/ios_test/1.0.0")
        #expect(events[0].stream == "ios.saved")
        #expect(events[0].outcome == .recorded)
        #expect(events[1].action == "click")
        #expect(events[1].activeInterface == nil)
        #expect(events[1].outcome.isDropped)
    }

    @Test
    func recordDoesNothingWhileDisabled() {
        let controller = WMFAnalyticsEventInspectorDataController(isEnabled: { false })

        controller.record(payload: payload(action: "impression"), stream: "ios.saved", outcome: .recorded)

        #expect(controller.events().isEmpty)
    }

    @Test
    func capacityDropsTheOldestEvents() {
        let controller = WMFAnalyticsEventInspectorDataController(capacity: 2, isEnabled: { true })

        for index in 0..<5 {
            controller.record(payload: payload(action: "action-\(index)"), stream: "ios.saved", outcome: .recorded)
        }

        #expect(controller.events().map(\.action) == ["action-3", "action-4"])
    }

    @Test
    func clearRemovesEveryEvent() {
        let controller = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        controller.record(payload: payload(action: "impression"), stream: "ios.saved", outcome: .recorded)

        controller.clear()

        #expect(controller.events().isEmpty)
    }

    @Test
    func eventStreamDeliversEventsRecordedAfterSubscribing() async {
        let controller = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        controller.record(payload: payload(action: "before"), stream: "ios.saved", outcome: .recorded)

        let stream = controller.eventStream()
        var iterator = stream.makeAsyncIterator()
        controller.record(payload: payload(action: "after"), stream: "ios.saved", outcome: .recorded)

        let delivered = await iterator.next()
        #expect(delivered?.action == "after")
    }

    @Test
    func payloadThatIsNotAJSONObjectStillPrintsAsText() {
        let raw = Data("not json".utf8)
        let event = WMFInspectedAnalyticsEvent(stream: "ios.saved", outcome: .recorded, payload: raw)

        #expect(event.action == nil)
        #expect(event.prettyPrintedPayload() == "not json")
    }

    @Test
    func prettyPrintedPayloadSortsKeys() {
        let event = WMFInspectedAnalyticsEvent(stream: "ios.saved", outcome: .recorded, payload: Data(#"{"b":1,"a":2}"#.utf8))

        #expect(event.prettyPrintedPayload() == "{\n  \"a\" : 2,\n  \"b\" : 1\n}")
    }

    @Test
    func concurrentRecordsAreNotLost() async {
        let controller = WMFAnalyticsEventInspectorDataController(isEnabled: { true })
        let payload = payload(action: "impression")

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    controller.record(payload: payload, stream: "ios.saved", outcome: .recorded)
                }
            }
        }

        #expect(controller.events().count == 50)
    }

    @Test
    func theDefaultProviderReadsTheDeveloperSetting() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFAnalyticsEventInspectorDataController()
            #expect(!controller.isEnabled)

            WMFDeveloperSettingsDataController.shared.showAnalyticsInspector = true
            #expect(controller.isEnabled)

            WMFDeveloperSettingsDataController.shared.showAnalyticsInspector = false
            #expect(!controller.isEnabled)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }
}
