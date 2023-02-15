import Foundation

final class RemoteNotificationsFunnel {
    public static let shared = RemoteNotificationsFunnel(dataStore: MWKDataStore.shared())
    private let dataStore: MWKDataStore
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let notification_id: Int
        let notification_wiki: String
        let notification_type: String
        let action: String
        let selection_token: String?
        let device_level_enabled: String
    }
    
    private func logEvent(notificationId: Int, notificationWiki: String, notificationType: String, action: NotificationsCenterActionData.LoggingLabel?, selectionToken: String?) {
        
        guard let action else {
            return
        }

        dataStore.notificationsController.notificationPermissionsStatus { [weak self] authStatus in
            guard self != nil else {
                return
            }
            
            DispatchQueue.main.async {
                let event = Event(notification_id: notificationId, notification_wiki: notificationWiki, notification_type: notificationType, action: action.stringValue, selection_token: selectionToken, device_level_enabled: authStatus.getAuthorizationStatusString())
                EventPlatformClient.shared.submit(stream: .remoteNotificationsInteraction, event: event)
            }
        }
        
    }
    
    public func logNotificationInteraction(notificationId: Int, notificationWiki: String, notificationType: String, action: NotificationsCenterActionData.LoggingLabel?, selectionToken: String?) {
        logEvent(notificationId: notificationId,
              notificationWiki: notificationWiki,
              notificationType: notificationType,
              action: action,
              selectionToken: selectionToken)
    }
}
