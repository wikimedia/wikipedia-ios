import Foundation

public class TestKitchenClient {

    public static let schemaAppBase = "/analytics/product_metrics/app/base/2.1.0"
    public static let streamAppBase = "product_metrics.app_base"

    private let contextController = ContextController()
    private let clientDataCallback: ClientDataCallback
    private let eventSender: EventSender
    private var sourceConfig: SourceConfig?

    public init(
        clientDataCallback: ClientDataCallback,
        eventSender: EventSender
    ) {
        self.clientDataCallback = clientDataCallback
        self.eventSender = eventSender
    }

    // MARK: - Public API

    public func getInstrument(name: String) -> InstrumentImpl {
        return InstrumentImpl(name: name, client: self)
    }

    public func submitInteraction(instrument: InstrumentImpl, interactionData: InteractionData) {
        let clientData = getClientData()
        let event = Event(
            schema: TestKitchenClient.schemaAppBase,
            stream: TestKitchenClient.streamAppBase,
            dt: iso8601Timestamp(),
            instrument: instrument,
            clientData: clientData,
            interactionData: interactionData
        )

        contextController.enrichEvent(event, streamConfig: streamConfig(for: TestKitchenClient.streamAppBase))

        eventSender.sendEvents([event])
    }

    public func updateSourceConfig(_ sourceConfig: SourceConfig) {
        self.sourceConfig = sourceConfig
    }

    // MARK: - Private

    private func getClientData() -> ClientData {
        return ClientData(
            agentData: clientDataCallback.getAgentData(),
            mediawikiData: clientDataCallback.getMediawikiData(),
            performerData: clientDataCallback.getPerformerData()
        )
    }

    private func streamConfig(for stream: String) -> StreamConfig {
        return sourceConfig?.getStreamConfig(byName: stream) ?? StreamConfig()
    }

    private func iso8601Timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
