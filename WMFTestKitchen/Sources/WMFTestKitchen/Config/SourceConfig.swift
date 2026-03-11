import Foundation

public class SourceConfig {
    public let streamConfigs: [String: StreamConfig]

    public init(streamConfigs: [String: StreamConfig]) {
        self.streamConfigs = streamConfigs
    }

    public func getStreamConfig(byName name: String) -> StreamConfig? {
        return streamConfigs[name]
    }
}
