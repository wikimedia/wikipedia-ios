
import Foundation

//Testable helper methods for service extension logic
public class NotificationServiceHelper {
    static func allNotificationsAreForSameTalkPage(notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) -> Bool {
        
        guard let firstTitle = notifications.first?.titleFull,
              let firstNamespace = notifications.first?.namespace,
              (firstNamespace == .talk || firstNamespace == .userTalk) else {
              return false
          }
        
        for notification in notifications {
            if (notification.titleFull != firstTitle) ||
                (notification.namespace != firstNamespace) {
                return false
            }
        }
        
        return true
    }
    
    public static func determineNotificationsToDisplayAndCache(fetchedNotifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, cachedNotifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) -> (notificationsToDisplay: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, notificationsToCache: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) {

        //Prune persisted keys of any > 1 day ago so the cache doesn't grow too big
        let recentCachedNotifications = cachedNotifications.filter { $0.isNewerThan(timeAgo: TimeInterval.oneDay) }
        
        //Prune fetched notifications > 10mins ago since a server delay should be no longer than that.
        let recentFetchedNotifications = fetchedNotifications.filter { $0.isNewerThan(timeAgo: TimeInterval.tenMinutes) }
        
        //Only consider new notifications that don't exist in cache for display
        let notificationsToDisplay = recentFetchedNotifications.subtracting(recentCachedNotifications)
        
        //New cache should keep track of recently cached notifications + new notifications to display
        let notificationsToCache = notificationsToDisplay.union(recentCachedNotifications)
        
        return (notificationsToDisplay, notificationsToCache)
    }
    
    public static func talkPageContent(for notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) -> (subtitle: String, body: String)? {
        
        guard NotificationServiceHelper.allNotificationsAreForSameTalkPage(notifications: notifications),
              let talkPageTitle = notifications.first?.titleFull else {
            return nil
        }
        
        let subtitle: String
        let body: String
        
        let messageText = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-messages-format", value: "{{PLURAL:%1$d|message|messages}}", comment: "Plural messages text to be inserted into push notification content - %1$d is replaced with the number of talk page messages."), notifications.count)
        subtitle = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-title-format", value: "New %1$@", comment: "Title text for a push notification that represents talk page messages - %1$@ is replaced with \"Messages\" text (can be plural or singular)."), messageText)
        
        if notifications.count == 1,
           let pushContentText = notifications.first?.pushContentText {
            body = pushContentText
        } else {
            body = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-body-format", value: "%1$d new %2$@ on %3$@", comment: "Body text for a push notification that represents talk page messages - %1$d is replaced with the number of talk page messages, %2$@ is replaced with \"messages\" text (can be plural or singular), and %3$@ is replaced with the talk page title. For example, \"3 new messages on User talk: Username\""), notifications.count, messageText, talkPageTitle)
        }
            
        return (subtitle, body)
    }
}
