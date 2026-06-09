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
}
