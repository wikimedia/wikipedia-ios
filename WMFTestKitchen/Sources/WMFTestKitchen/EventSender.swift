import Foundation

public protocol EventSender {
    func sendEvents(destinationEventService: DestinationEventService, events: [Event])
}
