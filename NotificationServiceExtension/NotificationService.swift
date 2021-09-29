
import UserNotifications
import WMF

class FakeLangProvider: WMFPreferredLanguageInfoProvider {
    func getPreferredContentLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }

    func getPreferredLanguageCodes(_ completion: @escaping ([String]) -> Void) {
        completion(["en"])
    }


}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    lazy var remoteNotificationsController: RemoteNotificationsController = {
        let configuration = Configuration.current
        let session = Session(configuration: configuration)
        let fakeProvider = FakeLangProvider()
        let controller = RemoteNotificationsController(session: session, configuration: configuration, preferredLanguageCodesProvider: fakeProvider)
        return controller
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        
        //TODO: We will modify content in all error cases to "New activity on Wikipedia" (see: https://phabricator.wikimedia.org/T288773 > Push Notification Content section)
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        self.bestAttemptContent = bestAttemptContent
        
        //TODO: We will modify this to pull the first page of only **unread** notifications, specifying a notnotifiertype=push parameter in the API call. This needs to be done as the next part of PRs for https://phabricator.wikimedia.org/T287310
        //This temporary call is just to confirm an authenticated call now works from an extension.
        remoteNotificationsController.fetchFirstPageNotifications {
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
