
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
        
        self.bestAttemptContent = bestAttemptContent
        
        //TODO: Should we consider versioning here? Bail now and show fallback content if current content is anything other than "checkEchoV1".
        
        let cache = sharedCache.loadCache()
        let project = RemoteNotificationsProject.language(cache.settings.primaryLanguageCode, nil, nil)
        
        apiController.getUnreadPushNotifications(from: project) { [weak self] fetchedNotifications, error in
            
            DispatchQueue.main.async {
                guard let self = self,
                      error == nil else {
                    contentHandler(bestAttemptContent)
                    return
                }
                
                let finalNotifications = NotificationServiceHelper.determineNotificationsToDisplayAndCache(fetchedNotifications: fetchedNotifications, cachedNotifications: cache.notifications)
                let finalNotificationsToDisplay = finalNotifications.notificationsToDisplay
                let finalNotificationsToCache = finalNotifications.notificationsToCache
                
                var newCache = cache
                newCache.notifications = finalNotificationsToCache
                self.sharedCache.saveCache(newCache)
                
                //specific handling for talk page types (New messages title, bundled body)
                if let talkPageContent = NotificationServiceHelper.talkPageContent(for: finalNotificationsToDisplay) {
                    bestAttemptContent.subtitle = talkPageContent.subtitle
                    bestAttemptContent.body = talkPageContent.body
                } else if finalNotificationsToDisplay.count == 1,
                       let pushContentText = finalNotificationsToDisplay.first?.pushContentText {
                    bestAttemptContent.body = pushContentText
                } else {
                    bestAttemptContent.body = self.fallbackPushContent
                }
                
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
            let bestAttemptContent =  bestAttemptContent {
            bestAttemptContent.body = fallbackPushContent
            contentHandler(bestAttemptContent)
        }
    }
}
