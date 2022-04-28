import Foundation

final class RemoteNotificationsFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    public static let shared = RemoteNotificationsFunnel(dataStore: MWKDataStore.shared())
    private let dataStore: MWKDataStore
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .remoteNotificationsInteraction
        let is_anon: Bool
        let notification_id: Int
        let notification_wiki: String
        let notification_type: String
        let action: String
        let selection_token: String?
        let primary_language: String
        let device_level_enabled: String
    }
    private func logEvent(notificationId: Int, notificationWiki: String, notificationType: String, action: NotificationsCenterActionData.LoggingLabel?, selectionToken: String?) {
        
        guard let action = action else {
            return
        }

        dataStore.notificationsController.notificationPermissionsStatus { [weak self] authStatus in
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                let event = Event(is_anon: self.isAnon.boolValue, notification_id: notificationId, notification_wiki: notificationWiki, notification_type: notificationType, action: action.stringValue, selection_token: selectionToken, primary_language: self.primaryLanguage(), device_level_enabled: authStatus.getAuthorizationStatusString())
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
