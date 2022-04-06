import Foundation

final class RemoteNotificationsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private enum Action: Codable {
        case toggleMarkRead
    }
    
    public static let shared = RemoteNotificationsFunnel()
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let action: Action
    }
    private func log(action: Action) {
        let event = Event(action: action)
        EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event)
    }
    
    public func logToggleMarkAsReadOrUnread() {
        log(action: .toggleMarkRead)
    }
}
