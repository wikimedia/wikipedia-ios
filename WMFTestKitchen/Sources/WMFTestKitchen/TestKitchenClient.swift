import Foundation

public class TestKitchenClient {

    public static let schemaAppBase = "/analytics/product_metrics/app/base/2.1.0"
    public static let streamAppBase = "product_metrics.app_base"

    private static let queueCapacity = 16

    private let contextController = ContextController()
    private let eventQueue: EventQueue
    private var eventProcessor: EventProcessor!
    private let clientDataCallback: ClientDataCallback
    private let logger: LogAdapter
    private var sourceConfig: SourceConfig?

    public init(
        clientDataCallback: ClientDataCallback,
        eventSender: EventSender,
        logger: LogAdapter
    ) {
        self.clientDataCallback = clientDataCallback
        self.logger = logger
        self.eventQueue = EventQueue(capacity: TestKitchenClient.queueCapacity)
        self.eventProcessor = EventProcessor(
            sourceConfig: { [weak self] in self?.sourceConfig },
            eventSender: eventSender,
            eventQueue: eventQueue,
            logger: logger
        )
    }

    // MARK: - Public API

    public func getInstrument(name: String) -> InstrumentImpl {
        return InstrumentImpl(name: name, client: self)
    }

    public func submitInteraction(instrument: InstrumentImpl, interactionData: InteractionData, pageData: PageData? = nil) {
        var clientData = getClientData()
        if let pageData {
            clientData = ClientData(agentData: clientData.agentData, pageData: pageData, mediawikiData: clientData.mediawikiData, performerData: clientData.performerData)
        }
        let event = Event(
            schema: TestKitchenClient.schemaAppBase,
            stream: TestKitchenClient.streamAppBase,
            dt: iso8601Timestamp(),
            instrument: instrument,
            clientData: clientData,
            interactionData: interactionData
        )

        contextController.enrichEvent(event, streamConfig: streamConfig(for: TestKitchenClient.streamAppBase))

        if !eventQueue.offer(event) {
            eventQueue.removeOldest()
            if !eventQueue.offer(event) {
                logger.warn("Failed to enqueue event after eviction.")
            }
        }
    }

    public func updateSourceConfig(_ sourceConfig: SourceConfig) {
        self.sourceConfig = sourceConfig
    }

    // MARK: - Lifecycle

    public func onAppPause() {
        eventProcessor.sendEnqueuedEvents()
    }

    public func onAppClose() {
        eventProcessor.sendEnqueuedEvents()
    }

    // MARK: - Private

    private func getClientData() -> ClientData {
        return ClientData(
            agentData: clientDataCallback.getAgentData(),
            pageData: nil,
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
