
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

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        
        //TODO: We will modify content in all error cases to "New activity on Wikipedia" (see: https://phabricator.wikimedia.org/T288773 > Push Notification Content section)
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        self.bestAttemptContent = bestAttemptContent
        
        //This temporary call is just to confirm an authenticated call now works from an extension.
        let cache = sharedCache.loadCache()
        let project = RemoteNotificationsProject.language(cache.settings.primaryLanguageCode, nil)
        
        apiController.getUnreadPushNotifications(from: project) { newNotifications, error in
            
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        //TODO: We will modify content in all error cases to "New activity on Wikipedia" (see: https://phabricator.wikimedia.org/T288773 > Push Notification Content section)
        if let contentHandler = contentHandler,
           let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
