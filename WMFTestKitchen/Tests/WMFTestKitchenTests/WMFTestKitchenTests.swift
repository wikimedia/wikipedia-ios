import XCTest
@testable import WMFTestKitchen

final class WMFTestKitchenTests: XCTestCase {

    func testStreamConfigDecodesNestedProducerConfig() throws {
        let json = """
        {
          "stream": "test.stream",
          "canary_events_enabled": true,
          "schema_title": "analytics/test/1.0.0",
          "producers": {
            "metrics_platform_client": {
              "provide_values": ["agent_app_install_id", "performer_session_id"]
            }
          }
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(StreamConfig.self, from: json)

        XCTAssertEqual(config.streamName, "test.stream")
        XCTAssertTrue(config.canaryEventsEnabled)
        XCTAssertEqual(config.schemaTitle, "analytics/test/1.0.0")
        XCTAssertEqual(
            config.producerConfig?.metricsPlatformClientConfig?.requestedValues,
            ["agent_app_install_id", "performer_session_id"]
        )
        XCTAssertTrue(config.hasRequestedContextValuesConfig())
    }

    func testStreamConfigReportsNoRequestedValuesWhenProducerMissing() throws {
        let json = """
        {
          "stream": "test.stream",
          "canary_events_enabled": false
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(StreamConfig.self, from: json)

        XCTAssertEqual(config.streamName, "test.stream")
        XCTAssertFalse(config.canaryEventsEnabled)
        XCTAssertNil(config.producerConfig)
        XCTAssertFalse(config.hasRequestedContextValuesConfig())
    }

    func testExperimentDataEncodesTheSchemaKeys() throws {
        let data = ExperimentData(enrolled: "semantic-search-phase-2", assigned: "treatment", coordinator: ExperimentData.coordinatorCustom, subjectId: "install-1")

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(data)) as? [String: String])

        XCTAssertEqual(json, ["enrolled": "semantic-search-phase-2", "assigned": "treatment", "coordinator": "custom", "subject_id": "install-1"])
    }

    func testExperimentExposureHasNoInstrument() throws {
        let sender = RecordingEventSender()
        let client = TestKitchenClient(clientDataCallback: EmptyClientData(), eventSender: sender)

        client.submitExperimentExposure(experimentData: ExperimentData(enrolled: "e", assigned: "control"))

        let event = try XCTUnwrap(sender.events.first)
        XCTAssertEqual(event.action, "experiment_exposure")
        XCTAssertNil(event.instrumentName)
        XCTAssertNil(event.funnelName)
        XCTAssertEqual(event.experimentData?.enrolled, "e")

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(event)) as? [String: Any])
        XCTAssertNil(json["instrument_name"])
    }
}

private final class RecordingEventSender: EventSender {
    var events: [Event] = []

    func sendEvents(_ events: [Event]) {
        self.events.append(contentsOf: events)
    }
}

private struct EmptyClientData: ClientDataCallback {
    func getAgentData() -> AgentData? { nil }
    func getMediawikiData() -> MediawikiData? { nil }
    func getPerformerData() -> PerformerData? { nil }
}
