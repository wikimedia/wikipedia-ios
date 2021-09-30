
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
    
    //TODO: Be sure the build script localizes this
    private let fallbackPushContent = WMFLocalizedString("notifications-push-fallback-title", value: "New activity on Wikipedia", comment: "Fallback content of a push notification whose content cannot be determined. Could be either due multiple notifications represented or errors.")

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
            
            guard let self = self,
                  error == nil else {
                contentHandler(bestAttemptContent)
                return
            }
            
            let finalNotifications = self.determineNewNotificationsAndUpdateCache(newNotifications: newNotifications, cache: cache)
            
            guard finalNotifications.count == 1 else {
                contentHandler(bestAttemptContent)
                return
            }
            
            guard let pushContentText = Array(finalNotifications)[0].pushContentText else {
                contentHandler(bestAttemptContent)
                return
            }
            
            bestAttemptContent.body = pushContentText
            contentHandler(bestAttemptContent)
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
