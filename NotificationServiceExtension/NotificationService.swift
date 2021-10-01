
import UserNotifications
import WMF

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    private lazy var apiController: RemoteNotificationsAPIController = {
        let configuration = Configuration.current
        let session = Session(configuration: configuration)
        let controller = RemoteNotificationsAPIController(session: session, configuration: configuration)
        return controller
    }()
    private let sharedCache = SharedContainerCache<PushNotificationsCache>.init(pathComponent: .pushNotificationsCache, defaultCache: { PushNotificationsCache(settings: .default, notifications: []) })
    
    private let fallbackPushContent = WMFLocalizedString("notifications-push-fallback-body-text", value: "New activity on Wikipedia", comment: "Fallback body content of a push notification whose content cannot be determined. Could be either due multiple notifications represented or errors.")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        bestAttemptContent.body = fallbackPushContent
        self.bestAttemptContent = bestAttemptContent
        
        let cache = sharedCache.loadCache()
        let project = RemoteNotificationsProject.language(cache.settings.primaryLanguageCode, nil)
        
        apiController.getUnreadPushNotifications(from: project) { [weak self] newNotifications, error in
            
            DispatchQueue.main.async {
                guard let self = self,
                      error == nil else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                let finalNotifications = self.determineNewNotificationsAndUpdateCache(newNotifications: newNotifications, cache: cache)
                
                //specific handling for talk page types (New messages title, bundled body)
                let handledAsTalkPage = self.handleTalkPageTypeNotificationsIfNeeded(notifications: finalNotifications, bestAttemptContent: bestAttemptContent, contentHandler: contentHandler)
                
                guard !handledAsTalkPage else {
                    return
                }
                
                //generic handling for other types
                guard finalNotifications.count == 1 else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                guard let pushContentText = finalNotifications.first?.pushContentText else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                bestAttemptContent.body = pushContentText
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
           let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func handleTalkPageTypeNotificationsIfNeeded(notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, bestAttemptContent: UNMutableNotificationContent, contentHandler: ((UNNotificationContent) -> Void)) -> Bool {
        
        if allNotificationsAreForSameTalkPage(notifications: notifications) {
            let messageText = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-messages-format", value: "{{PLURAL:%1$d|message|messages}}", comment: "Plural messages text to be inserted into push notification content - %1$d is replaced with the number of talk page messages."), notifications.count)
            bestAttemptContent.subtitle = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-title-format", value: "New %1$@", comment: "Title text for a push notification that represents talk page messages - %1$@ is replaced with \"Messages\" text (can be plural or singular)."), messageText)
            
            if notifications.count == 1 {
                guard let pushContentText = notifications.first?.pushContentText else {
                    contentHandler(bestAttemptContent)
                    return true
                }
                
                bestAttemptContent.body = pushContentText
                contentHandler(bestAttemptContent)
                return true
            } else {
                
                guard let talkPageTitle = notifications.first?.titleFull else {
                    contentHandler(bestAttemptContent)
                    return true
                }
                
                bestAttemptContent.body = String.localizedStringWithFormat(WMFLocalizedString("notifications-push-talk-body-format", value: "%1$d new %2$@ on %3$@", comment: "Body text for a push notification that represents talk page messages - %1$d is replaced with the number of talk page messages, %2$@ is replaced with \"messages\" text (can be plural or singular), and %3$@ is replaced with the talk page title. For example, \"3 new messages on User talk: Username\""), notifications.count, messageText, talkPageTitle)
                contentHandler(bestAttemptContent)
                return true
            }
        }
        
        return false
    }
    
    private func allNotificationsAreForSameTalkPage(notifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) -> Bool {
        
        guard notifications.count > 0 else {
            return false
        }
        
        typealias TalkPageName = String
        typealias NotificationKey = String
        var talkDictionary: [TalkPageName: [NotificationKey]] = [:]
        
        for notification in notifications {
            guard let namespaceKey = notification.namespaceKey,
                  let namespace = PageNamespace(rawValue: namespaceKey),
                  let titleFull = notification.titleFull,
                  (namespace == .talk || namespace == .userTalk) else {
                continue
            }
            
            let newValue = (talkDictionary[titleFull] ?? []) + [notification.key]
            talkDictionary[titleFull] = newValue
        }
        
        guard talkDictionary.count == 1,
              let firstElement = talkDictionary.first else {
            return false
        }
        
        let groupedNotifications = firstElement.value
        return groupedNotifications.count == notifications.count
    }
    
    private func determineNewNotificationsAndUpdateCache(newNotifications: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>, cache: PushNotificationsCache) -> Set<RemoteNotificationsAPIController.NotificationsResult.Notification> {
        
        //Determine which notifications are truely new - filter out those pushes that have already been considered in the cache.
        let cachedNotifications = cache.notifications
        
        //Prune persisted keys of any > 1 day? ago so the cache doesn't grow too big
        let oneDay = TimeInterval(60 * 60 * 24)
        let recentCachedNotifications = cachedNotifications.filter { notification in
            guard let date = notification.date else {
                return false
            }

            return date > Date().addingTimeInterval(-oneDay)
        }
        
        //Prune new notifications > 10mins ago since a server delay should be no longer than that.
        let tenMins = TimeInterval(60 * 10)
        let recentNewNotifications = newNotifications.filter { notification in
            guard let date = notification.date else {
                return false
            }

            return date > Date().addingTimeInterval(-tenMins)
        }
        
        //Only consider new notifications that don't exist in cache
        let finalNotifications = recentNewNotifications.subtracting(recentCachedNotifications)
        
        //update cache
        let newNotificationsToCache = finalNotifications.union(recentCachedNotifications)
        var newCache = cache
        newCache.notifications = newNotificationsToCache
        self.sharedCache.saveCache(newCache)
        
        return finalNotifications
    }

}
