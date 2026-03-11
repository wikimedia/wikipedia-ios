import Foundation

class EventProcessor {
    private let sourceConfig: () -> SourceConfig?
    private let eventSender: EventSender
    private let eventQueue: EventQueue
    private let logger: LogAdapter
    private let processingQueue = DispatchQueue(label: "org.wikimedia.testkitchen.eventprocessor")

    init(
        sourceConfig: @escaping () -> SourceConfig?,
        eventSender: EventSender,
        eventQueue: EventQueue,
        logger: LogAdapter
    ) {
        self.sourceConfig = sourceConfig
        self.eventSender = eventSender
        self.eventQueue = eventQueue
        self.logger = logger
    }

    func sendEnqueuedEvents() {
        processingQueue.async { [weak self] in
            self?.processPendingEvents()
        }
    }

    private func processPendingEvents() {
        let pending = eventQueue.drainAll()
        guard !pending.isEmpty else { return }

        // Group events by destination service
        var eventsByDestination: [DestinationEventService: [Event]] = [:]
        for event in pending {
            let destination: DestinationEventService
            if let config = sourceConfig(), let streamConfig = config.getStreamConfig(byName: event.meta.stream) {
                destination = streamConfig.destinationEventService
            } else {
                destination = .analytics
            }
            eventsByDestination[destination, default: []].append(event)
        }

        for (destination, events) in eventsByDestination {
            eventSender.sendEvents(destinationEventService: destination, events: events)
            logger.info("\(events.count) events sent successfully")
        }
    }
}
