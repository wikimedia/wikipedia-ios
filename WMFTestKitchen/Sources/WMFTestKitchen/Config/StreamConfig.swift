import Foundation

public class StreamConfig: Codable {
    public var streamName: String = ""
    public var canaryEventsEnabled: Bool = false
    public var schemaTitle: String?
    public var producerConfig: ProducerConfig?

    public func hasRequestedContextValuesConfig() -> Bool {
        return producerConfig?.metricsPlatformClientConfig?.requestedValues != nil
    }

    enum CodingKeys: String, CodingKey {
        case streamName = "stream"
        case canaryEventsEnabled = "canary_events_enabled"
        case schemaTitle = "schema_title"
        case producerConfig = "producers"
    }

    public struct ProducerConfig: Codable {
        public var metricsPlatformClientConfig: MetricsPlatformClientConfig?

        enum CodingKeys: String, CodingKey {
            case metricsPlatformClientConfig = "metrics_platform_client"
        }
    }

    public struct MetricsPlatformClientConfig: Codable {
        public var requestedValues: [String]?

        enum CodingKeys: String, CodingKey {
            case requestedValues = "provide_values"
        }
    }
}
