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
    private let sharedCache = SharedContainerCache.init(fileName: SharedContainerCacheCommonNames.pushNotificationsCache)
    
    private let fallbackPushContent = WMFLocalizedString("notifications-push-fallback-body-text", value: "New activity on Wikipedia", comment: "Fallback body content of a push notification whose content cannot be determined. Could be either due multiple notifications represented or errors.")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        self.bestAttemptContent = bestAttemptContent
        
        guard bestAttemptContent.body == EchoModelVersion.current else {
            bestAttemptContent.body = fallbackPushContent
            contentHandler(bestAttemptContent)
            return
        }
        
        let cache = sharedCache.loadCache() ?? PushNotificationsCache(settings: .default, notifications: [])
        let project = WikimediaProject.wikipedia(cache.settings.primaryLanguageCode, cache.settings.primaryLocalizedName, nil)
        
        let fallbackPushContent = self.fallbackPushContent
        
        apiController.getUnreadPushNotifications(from: project) { [weak self] fetchedNotifications, error in
            
            DispatchQueue.main.async {
                guard let self = self,
                      error == nil else {
                    bestAttemptContent.body = fallbackPushContent
                    contentHandler(bestAttemptContent)
                    return
                }
                
                let finalNotifications = NotificationServiceHelper.determineNotificationsToDisplayAndCache(fetchedNotifications: fetchedNotifications, cachedNotifications: cache.notifications)
                let finalNotificationsToDisplay = finalNotifications.notificationsToDisplay
                let finalNotificationsToCache = finalNotifications.notificationsToCache
                
                var newCache = cache
                newCache.notifications = finalNotificationsToCache
                self.sharedCache.saveCache(newCache)
                
                // specific handling for talk page types (New messages title, bundled body)
                if let talkPageContent = NotificationServiceHelper.talkPageContent(for: finalNotificationsToDisplay) {
                    bestAttemptContent.subtitle = talkPageContent.subtitle
                    bestAttemptContent.body = talkPageContent.body
                } else if finalNotificationsToDisplay.count == 1,
                       let pushContentText = finalNotificationsToDisplay.first?.pushContentText {
                    bestAttemptContent.body = pushContentText
                } else {
                    bestAttemptContent.body = fallbackPushContent
                }

                // Assigning interruption level and relevance score only available starting on iOS 15
                if finalNotifications.notificationsToDisplay.count == 1, let notification = finalNotifications.notificationsToDisplay.first {
                    let priority = RemoteNotification.typeFrom(notification: notification).priority
                    bestAttemptContent.interruptionLevel = priority.interruptionLevel
                    bestAttemptContent.relevanceScore = priority.relevanceScore
                } else {
                    if NotificationServiceHelper.allNotificationsAreForSameTalkPage(notifications: finalNotificationsToDisplay) {
                        bestAttemptContent.interruptionLevel = RemoteNotificationType.mentionInTalkPage.priority.interruptionLevel
                        bestAttemptContent.relevanceScore = RemoteNotificationType.mentionInTalkPage.priority.relevanceScore
                    } else {
                        bestAttemptContent.interruptionLevel = RemoteNotificationType.bulkPriority.interruptionLevel
                        bestAttemptContent.relevanceScore = RemoteNotificationType.bulkPriority.relevanceScore
                    }
                }

                let displayContentIdentifiers = finalNotificationsToDisplay.compactMap { PushNotificationContentIdentifier(key: $0.key, date: $0.date) }
                PushNotificationContentIdentifier.save(displayContentIdentifiers, to: &bestAttemptContent.userInfo)

                bestAttemptContent.badge = NSNumber(value: newCache.currentUnreadCount + finalNotificationsToDisplay.count)
                
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.body = fallbackPushContent
            contentHandler(bestAttemptContent)
        }
    }
}
