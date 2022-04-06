import Foundation

final class RemoteNotificationsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    private enum Action: Codable {
        case toggleMarkRead
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let action: Action
    }
    private func log(action: Action, domain: String?) {
        let event = Event(action: action)
        EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event, domain: domain)
    }
    
    public func logToggleMarkAsReadOrUnread(url: URL) {
        log(action: .toggleMarkRead, domain: url.wmf_site?.host)
    }
}
